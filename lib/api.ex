defmodule Tweexir.Api do
  require Logger
  alias Tweexir.Client
  alias Tweexir.Stream

  @doc"""
  Returns the numerical count of Tweets for a query over the last seven days.
  """
  def recent_tweets_count(query) do
    ("/tweets/counts/recent?" <> URI.encode_query(query))
    |> Client.get()
    |> case do
      {:ok, %HTTPoison.Response{body: body}} -> Poison.decode(body)
      {:error, %HTTPoison.Error{reason: reason}} -> {:error, reason}
    end
  end

  def stream(rules) do
    rules_url = "/tweets/search/stream/rules"

    with {:ok, rules_payload} <- Poison.encode(%{"add" => rules}),
         {:ok, prev_rules} <- get_stream_rules(rules_url),
         {:ok, _} <- delete_stream_rules(rules_url, prev_rules),
         {:ok, _} <-
           set_stream_rules(rules_url, rules_payload) do
      {:ok, stage} = Stream.start_link("/tweets/search/stream")

      case Client.get("/tweets/search/stream", [], recv_timeout: :infinity, stream_to: stage) do
        {:ok, %HTTPoison.AsyncResponse{}} ->
          Logger.info("Start streaming")
          {:ok, GenStage.stream([{stage, [min_demand: 500, max_demand: 1000]}])}

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, reason}
      end
    end
  end

  defp get_stream_rules(url) do
    url
    |> Client.get()
    |> case do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> Poison.decode(body)
      {:error, %HTTPoison.Error{reason: reason}} -> {:error, reason}
    end
  end

  defp delete_stream_rules(url, rules) do
    with {:ok, payload} <-
           Poison.encode(%{"delete" => %{"ids" => Enum.map(rules["data"], fn r -> r["id"] end)}}) do
      url
      |> Client.post(payload, [{"Content-Type", "application/json"}])
      |> case do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> {:ok, body}
        {:error, %HTTPoison.Error{reason: reason}} -> {:error, reason}
      end
    end
  end

  defp set_stream_rules(url, rules) do
    url
    |> Client.post(rules, [{"Content-Type", "application/json"}])
    |> case do
      {:ok, %HTTPoison.Response{} = r} when r.status_code in 200..202 ->
        {:ok, r.body}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
