defmodule Tweexir.Api do
  @moduledoc false
  require Logger
  alias Tweexir.Http.Client
  alias Tweexir.Stream
  alias Tweexir.StreamProducer

  @doc """
  Returns the Tweets mentioning a specific Twitter user, including query to filter
  results
  """
  def user_mentions(user_id, query) do
    Client.get("/users/#{user_id}/mentions?" <> URI.encode_query(query))
  end

  @doc """
  Returns the Tweets published by a specific Twitter account, including
  query to filter results.
  """
  def user_timeline(user_id, query) do
    Client.get("/users/#{user_id}/tweets?" <> URI.encode_query(query))
  end

  @doc """
  Returns the public Tweets posted during the last week filtered by a query.
  """
  def recent_search(query) do
    Client.get("/tweets/search?" <> URI.encode_query(query))
  end

  @doc """
  Returns the numerical count of Tweets for a query for the entire archive of the
  public Tweets.
  """
  def tweets_count(query) do
    Client.get("/tweets/counts/all?" <> URI.encode_query(query))
  end

  @doc """
  Returns the numerical count of Tweets for a query over the last seven days.
  """
  def recent_tweets_count(query) do
    Client.get("/tweets/counts/recent?" <> URI.encode_query(query))
  end

  @doc """
  Connects to a stream which delivers a roughly 1% random sample of publicly available
  Tweets in real-time.
  """
  def sample_stream(stream) do
    if stream == :producer do
      {:ok, stage} = StreamProducer.start_link("/tweets/sample/stream")
      {:ok, GenStage.stream([{stage, [min_demand: 50, max_demand: 500]}])}
    else
      {:ok, Stream.stream("/tweets/sample/stream")}
    end
  end

  @doc """
  Allows to filter the real-time stream of public Tweets by a query.
  """
  def stream(stream, rules) do
    rules_url = "/tweets/search/stream/rules"

    with :ok <- Stream.reset_rules(rules_url, rules) do
      if stream == :producer do
        {:ok, stage} = StreamProducer.start_link("/tweets/search/stream")
        {:ok, GenStage.stream([{stage, [min_demand: 500, max_demand: 1000]}])}
      else
        {:ok, Stream.stream("/tweets/search/stream")}
      end
    end
  end
end
