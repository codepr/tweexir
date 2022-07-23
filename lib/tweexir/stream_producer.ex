defmodule Tweexir.StreamProducer do
  @moduledoc false
  use GenStage
  alias Tweexir.Stream, as: TweetStream

  @doc """
  Starts a stage as part of a supervision tree.
  """
  @spec start_link(String.t(), Keyword.t()) :: GenServer.on_start()
  def start_link(url, options \\ []) do
    GenStage.start_link(__MODULE__, url, options)
  end

  #
  # Callbacks
  #

  @doc false
  def init(url) do
    stream = TweetStream.stream(url)
    {:producer, stream}
  end

  @doc false
  def handle_demand(demand, stream) do
    tweets = stream |> Enum.take(demand)
    {:noreply, tweets, stream}
  end

  def handle_info(%HTTPoison.AsyncChunk{} = chunk, stream) do
    case Poison.decode(chunk.chunk) do
      {:ok, tweets} -> {:noreply, [tweets["data"]], stream}
      {:error, error} -> {:noreply, [error], stream}
    end
  end
end
