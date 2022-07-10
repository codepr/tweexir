defmodule Tweexir.Stream do
  use GenStage
  alias Tweexir.Client

  @doc """
  Starts a stage as part of a supervision tree.
  """
  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(options \\ []) do
    GenStage.start_link(__MODULE__, [], options)
  end

  #
  # Callbacks
  #

  @doc false
  def init([]) do
    {:producer, %{chunk: nil, demand: 0}}
  end

  @doc false
  def handle_demand(demand, state) do
    {:noreply, [], %{state | demand: state.demand + demand}}
  end

  def handle_info(%HTTPoison.AsyncResponse{} = chunk, state) do
    if state.demand > 0, do: Client.stream_next(chunk)
    {:noreply, [], state}
  end

  def handle_info(%HTTPoison.AsyncChunk{} = chunk, state) do
    case Poison.decode(chunk.chunk) do
      {:ok, tweets} -> {:noreply, [tweets], state}
      {:error, error} -> {:noreply, [error], state}
    end
  end

  def handle_info(%HTTPoison.AsyncEnd{} = _response, state) do
    {:stop, "Connection closed", state}
  end

  def handle_info(%HTTPoison.AsyncStatus{code: code}, state) do
    {:noreply, [code], state}
  end

  def handle_info(%HTTPoison.AsyncHeaders{headers: headers}, state) do
    reply =
      Enum.filter(headers, fn {k, _v} -> k in ["x-rate-limit-limit", "x-rate-limit-remaining"] end)

    {:noreply, [reply], state}
  end

  def terminate(reason, state) do
    {:noreply, [reason], state}
  end
end
