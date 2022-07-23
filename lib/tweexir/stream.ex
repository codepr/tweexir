defmodule Tweexir.Stream do
  alias Tweexir.Client

  @default_timeout 60_000

  def stream(url) do
    Stream.resource(
      fn -> source(url) end,
      &next_chunk/1,
      &sink/1
    )
  end

  defp source(url) do
    Client.get(url, [], recv_timeout: :infinity, stream_to: self())
  end

  defp next_chunk({:ok, %HTTPoison.AsyncResponse{} = response}) do
    next_chunk(response)
  end

  defp next_chunk(%HTTPoison.AsyncResponse{id: id} = response) do
    receive do
      %HTTPoison.AsyncChunk{id: ^id, chunk: chunk} ->
        HTTPoison.stream_next(response)

        case Poison.decode(chunk) do
          {:ok, tweet} -> {[tweet], response}
          {:error, error} -> {[error], response}
        end

      %HTTPoison.AsyncEnd{id: ^id} ->
        {:halt, response}

      _ ->
        {[], response}
    after
      timeout() ->
        {:halt, response}
    end
  end

  defp sink(%HTTPoison.AsyncResponse{id: id}) do
    :hackney.stop_async(id)
  end

  defp timeout do
    Application.get_env(:stream, :timeout, @default_timeout)
  end
end
