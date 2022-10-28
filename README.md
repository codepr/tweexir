# Tweexir

Twitter client library for v2 APIs.

## Quickstart

Requires a `Bearer token` in the `config/config.exs` to work.

```elixir
$ iex -S mix
Interactive Elixir - press Ctrl+C to exit (type h() ENTER for help)
```
```elixir
iex(1)> {:ok, stream} = Tweexir.Api.sample_stream()

17:26:54.928 [info]  Start streaming
{:ok, #Function<51.58486609/2 in Stream.resource/3>}

iex(2)> Enum.each stream, &IO.inspect/1
:ok
```
## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `tweexir` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tweexir, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/tweexir>.

