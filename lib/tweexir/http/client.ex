defmodule Tweexir.Http.Client do
  @moduledoc false
  alias Tweexir.Http.Base

  def get(url, headers \\ [], opts \\ []) do
    url
    |> Base.get(headers, opts)
    |> handle_error()
  end

  def post(url, body, headers \\ [], opts \\ []) do
    url
    |> Base.post(body, headers, opts)
    |> handle_error()
  end

  defp handle_error({:ok, %HTTPoison.Response{status_code: status_code, body: body}})
       when status_code in 200..299,
       do: {:ok, body}

  defp handle_error({:ok, %HTTPoison.Response{body: body}}), do: {:http_error, body}
  defp handle_error({:error, %HTTPoison.Error{reason: reason}}), do: {:error, reason}
end
