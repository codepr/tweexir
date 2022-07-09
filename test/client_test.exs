defmodule Tweexir.ClientTest do
  use ExUnit.Case
  alias Tweexir.Client

  describe "process_request_url/1" do
    test "returns the joined URI starting with https://api.twitter.com/2/" do
      assert Client.process_request_url("/foo") == "https://api.twitter.com/2/foo"
      assert Client.process_request_url("/foo/bar") == "https://api.twitter.com/2/foo/bar"
    end

    test "returns the joined URI starting with https://api.twitter.com/2/ with a non-leading / relative path" do
      assert Client.process_request_url("foo") == "https://api.twitter.com/2/foo"
      assert Client.process_request_url("foo/bar") == "https://api.twitter.com/2/foo/bar"
    end
  end

  describe "process_request_headers/1" do
    test "update headers with the authentication token" do
      assert(
        Client.process_request_headers([:ContentType, "application/json"]) == [
          {:Authorization, "Bearer test-token"},
          :ContentType, "application/json"
        ]
      )
    end
  end
end
