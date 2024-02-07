defmodule OllamaLive.TestOllama do
  def run do
    sys_prompt =
      "You are a game desinger and developer of 2D games. You have experience as designer and a javascript developer."

    prompt =
      "What is WebGL?"

    prompt_with_setting = "[INST] <<SYS>>#{sys_prompt}<</SYS>>\n\n#{prompt} [/INST]"

    Ollama.call(prompt_with_setting, fn data ->
      txt = Enum.reduce(data, "", fn d, acc -> Map.get(d, "response", "") <> acc end)
      IO.inspect(txt)
    end)
  end
end
