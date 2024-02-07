defmodule OllamaLiveWeb.InterfaceLive.Index do
  use OllamaLiveWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :start_of_code_block, true)

    {:ok, stream(socket, :messages, [])}
  end

  @impl true
  def handle_event("run_model", _, socket) do
    start_llm_run(self())
    {:noreply, socket}
  end

  @impl true
  def handle_info({:llm_response, txt}, socket) do
    id = Ecto.UUID.generate()

    {txt, socket} =
      if String.contains?(txt, "```") do
        if socket.assigns.start_of_code_block do
          {String.replace(txt, "```", "<code>"), assign(socket, :start_of_code_block, false)}
        else
          {String.replace(txt, "```", "</code>"), assign(socket, :start_of_code_block, true)}
        end
      else
        {txt, socket}
      end

    {:noreply, stream_insert(socket, :messages, %{id: id, txt: txt})}
  end

  def start_llm_run(live_view_pid) do
    sys_prompt =
      "You are a game desinger and developer of 2D games. You have experience as designer and a javascript developer."

    prompt =
      "How can I make a GUI for my games?"

    prompt_with_setting = "[INST] <<SYS>>#{sys_prompt}<</SYS>>\n\n#{prompt} [/INST]"

    Task.start(fn ->
      Ollama.call(prompt_with_setting, fn data ->
        txt = Enum.reduce(data, "", fn d, acc -> Map.get(d, "response", "") <> acc end)
        send(live_view_pid, {:llm_response, txt})
      end)
    end)
  end
end
