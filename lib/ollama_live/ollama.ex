defmodule Ollama do
  @timeout 300_000
  @batch_size 15
  @url "http://localhost:11434/api/generate"

  defp decode_body("", _), do: :ok
  defp decode_body("[DONE]", _), do: :ok
  # cb.(Jason.decode!(json))
  defp decode_body(json), do: Jason.decode!(json)

  def call(prompt, cb) do
    finch_req_fun = fn request, finch_request, finch_name, finch_options ->
      stream_acc_fun = fn
        {:status, status}, response ->
          %{response | status: status}

        {:headers, headers}, response ->
          %{response | headers: headers}

        {:data, data}, response ->
          body =
            data
            |> String.split("data: ")
            |> Enum.map(fn str ->
              str
              |> String.trim()
              |> decode_body()
            end)
            |> Enum.filter(fn d -> d != :ok end)

          old_body = if response.body == "", do: [], else: response.body
          new_body = body ++ old_body

          if rem(length(new_body), @batch_size) == 0 do
            cb.(Enum.take(new_body, @batch_size))
          end

          %{response | body: new_body}
      end

      accumulator = Req.Response.new()

      case Finch.stream(finch_request, finch_name, accumulator, stream_acc_fun, finch_options) do
        {:ok, response} -> {request, response}
        {:error, exception} -> {request, exception}
      end
    end

    payload =
      Jason.encode!(%{
        "model" => "llama2",
        "prompt" => prompt,
        "stream" => true
      })

    Req.post!(@url, body: payload, finch_request: finch_req_fun, receive_timeout: @timeout)
  end
end
