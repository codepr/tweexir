defmodule Tweexir.Stream do
  @moduledoc false
  alias Tweexir.Http.Client

  @default_timeout 60_000

  def get_rules(url) do
    url
    |> Client.get()
    |> from_json()
  end

  def set_rules(url, rules) do
    url
    |> Client.post(rules, [{"Content-Type", "application/json"}])
    |> from_json()
  end

  def delete_rules(url, rules) do
    with {:ok, payload} <-
           Jason.encode(%{"delete" => %{"ids" => Enum.map(rules["data"], fn r -> r["id"] end)}}) do
      url
      |> Client.post(payload, [{"Content-Type", "application/json"}])
      |> from_json()
    end
  end

  def reset_rules(url, rules) do
    with {:ok, payload} <- Jason.encode(%{"add" => rules}),
         {:ok, existing_rules} <- get_rules(url),
         {:ok, _} <- delete_rules(url, existing_rules) do
      set_rules(url, payload)
      :ok
    end
  end

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

        case Jason.decode(chunk) do
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

  defp from_json({:ok, io_data}), do: Jason.decode!(io_data)
  defp from_json(response_error), do: response_error
end
