defmodule Tweexir.Http.Base do
  @moduledoc false
  use HTTPoison.Base

  def process_request_url(url) do
    if has_scheme?(url) do
      url
    else
      api_url() <> "/#{api_version()}" <> if String.first(url) == "/", do: url, else: "/" <> url
    end
  end

  def process_request_headers(headers) do
    Keyword.put_new(
      headers,
      :Authorization,
      "Bearer #{bearer_token()}"
    )
  end

  defp has_scheme?(url), do: URI.parse(url).scheme != nil

  defp api_url, do: "https://api.twitter.com"

  defp api_version, do: 2

  defp bearer_token, do: Application.fetch_env!(:tweexir, :bearer_token)
end
