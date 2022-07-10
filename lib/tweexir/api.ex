defmodule Tweexir.Api do
  require Logger
  alias Tweexir.Client
  alias Tweexir.Stream

  @doc """
  Returns the Tweets mentioning a specific Twitter user, including query to filter
  results
  """
  def user_mentions(user_id, query) do
    do_get("/users/#{user_id}/mentions?" <> URI.encode_query(query))
  end

  @doc """
  Returns the Tweets published by a specific Twitter account, including
  query to filter results.
  """
  def user_timeline(user_id, query) do
    do_get("/users/#{user_id}/tweets?" <> URI.encode_query(query))
  end

  @doc """
  Returns the public Tweets posted during the last week filtered by a query.
  """
  def recent_search(query) do
    do_get("/tweets/search?" <> URI.encode_query(query))
  end

  @doc """
  Returns the numerical count of Tweets for a query for the entire archive of the
  public Tweets.
  """
  def tweets_count(query) do
    do_get("/tweets/counts/all?" <> URI.encode_query(query))
  end

  @doc """
  Returns the numerical count of Tweets for a query over the last seven days.
  """
  def recent_tweets_count(query) do
    do_get("/tweets/counts/recent?" <> URI.encode_query(query))
  end

  @doc """
  Connects to a stream which delivers a roughly 1% random sample of publicly available
  Tweets in real-time.
  """
  def sample_stream do
    {:ok, stage} = Stream.start_link()

    case Client.get("/tweets/sample/stream", [], recv_timeout: :infinity, stream_to: stage) do
      {:ok, %HTTPoison.AsyncResponse{}} ->
        Logger.info("Start streaming")
        {:ok, GenStage.stream([{stage, [min_demand: 500, max_demand: 1000]}])}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  @doc """
  Allows to filter the real-time stream of public Tweets by a query.
  """
  def stream(rules) do
    rules_url = "/tweets/search/stream/rules"

    with {:ok, rules_payload} <- Poison.encode(%{"add" => rules}),
         {:ok, prev_rules} <- get_stream_rules(rules_url),
         {:ok, _} <- delete_stream_rules(rules_url, prev_rules),
         {:ok, _} <-
           set_stream_rules(rules_url, rules_payload) do
      {:ok, stage} = Stream.start_link()

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
    do_get(url)
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

  defp do_get(url) do
    url
    |> Client.get()
    |> case do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}}
      when status_code in 200..299 ->
        Poison.decode(body)

      {:ok, %HTTPoison.Response{body: body}} ->
        {:error, Poison.decode!(body)}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
