defmodule Tweexir.Client do
  use HTTPoison.Base

  def process_request_url(url) do
    unless URI.parse(url).scheme do
      api_url() <> "/#{api_version()}" <> if String.first(url) == "/", do: url, else: "/" <> url
    else
      url
    end
  end

  def process_request_headers(headers) do
    Keyword.put_new(
      headers,
      :Authorization,
      "Bearer #{bearer_token()}"
    )
  end

  defp api_url, do: "https://api.twitter.com"

  defp api_version, do: 2

  defp bearer_token, do: Application.fetch_env!(:twitter, :bearer_token)
end
