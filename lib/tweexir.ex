defmodule Tweexir do
  @moduledoc """
  Twitter client with OAuth1 and OAuth2 support.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Tweexir.hello()
      :world

  """
  use Application

  @impl Application
  def start(_type, _args) do
    children = []
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defdelegate user_timeline(user_id, query), to: Tweexir.Api
  defdelegate user_mentions(user_id, query), to: Tweexir.Api
  defdelegate recent_search(query), to: Tweexir.Api
  defdelegate tweets_count(query), to: Tweexir.Api
  defdelegate recent_tweets_count(query), to: Tweexir.Api
  defdelegate stream(query, rules), to: Tweexir.Api
  defdelegate sample_stream(query), to: Tweexir.Api
end
