defmodule OllamaLiveWeb.InterfaceLive.Index do
  use OllamaLiveWeb, :live_view

  @system_prompt "You are a game desinger and developer of 2D games. You have experience as designer and a javascript developer."

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(
        form:
          to_form(
            OllamaLive.Chat.Message.changeset(%OllamaLive.Chat.Message{}, %{
              content: "What is WebGL?",
              system_prompt: @system_prompt
            })
          )
      )

    {:ok, stream(socket, :messages, [])}
  end

  @impl true
  def handle_event(
        "run_model",
        %{"message" => %{"content" => prompt, "system_prompt" => system_prompt}},
        socket
      ) do
    start_llm_run(self(), system_prompt, prompt)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:llm_response, txt}, socket) do
    id = Ecto.UUID.generate()

    {:noreply, stream_insert(socket, :messages, %{id: id, txt: String.trim(txt)})}
  end

  def start_llm_run(live_view_pid, sys_prompt, prompt) do
    prompt_with_setting = "[INST] <<SYS>>#{sys_prompt}<</SYS>>\n\n#{prompt} [/INST]"

    Task.start(fn ->
      Ollama.call(prompt_with_setting, fn data ->
        txt = Enum.reduce(data, "", fn d, acc -> Map.get(d, "response", "") <> acc end)
        send(live_view_pid, {:llm_response, txt})
      end)
    end)
  end
end
