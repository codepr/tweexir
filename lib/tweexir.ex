defmodule Tweexir do
  @moduledoc """
  Documentation for `Tweexir`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Tweexir.hello()
      :world

  """
  @moduledoc """
  Twitter client with OAuth1 and OAuth2 support.
  """

  defdelegate user_timeline(user_id, query), to: Tweexir.Client
  defdelegate user_mentions(user_id, query), to: Tweexir.Client
  defdelegate recent_search(query), to: Tweexir.Client
  defdelegate tweets_count(query), to: Tweexir.Client
  defdelegate recent_tweets_count(query), to: Tweexir.Client
  defdelegate stream(query), to: Tweexir.Client
  defdelegate sample_stream(query), to: Tweexir.Client
end
