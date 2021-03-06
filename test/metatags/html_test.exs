defmodule Metatags.HTMLTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Metatags.HTML
  alias Phoenix.HTML.Safe

  describe "from_conn/1" do
    test "returns the metatags as html" do
      conn = Metatags.put(build_conn(), "title", "my title")

      assert "<title>my title</title>" = safe_to_string(HTML.from_conn(conn))
    end

    test "returns a Phoenix.HTML.Safe" do
      conn = Metatags.put(build_conn(), "title", "my title")

      assert [{:safe, _}] = HTML.from_conn(conn)
    end

    test "raises an error when not passed a %Plug.Conn{}" do
      conn = %{}

      assert_raise ArgumentError, fn -> HTML.from_conn(conn) end
    end

    test "prints a list of keywords as a comma separated string" do
      conn = Metatags.put(build_conn(), :keywords, ["metatags", "awesome"])

      assert safe_to_string(HTML.from_conn(conn)) =~
               ~s(<meta content="metatags, awesome" property="keywords">)
    end

    test "prints nested maps as keys with prefixes" do
      conn = Metatags.put(build_conn(), :prefix, %{key: "value"})

      assert safe_to_string(HTML.from_conn(conn)) =~
               ~s(<meta content="value" property="prefix:key">)
    end

    test "prints a key and value with name and content attributes" do
      conn = Metatags.put(build_conn(), :anything, "value")

      assert safe_to_string(HTML.from_conn(conn)) =~
               ~s(<meta content="value" property="anything">)
    end

    test "adds the sitename as suffix to title when configured" do
      default_options = [sitename: "page"]
      conn = Metatags.put(build_conn(default_options), :title, "Welcome")

      assert safe_to_string(HTML.from_conn(conn)) =~
               "<title>Welcome - page</title>"
    end

    test "prints the sitename when no title is set" do
      default_options = [sitename: "page"]
      conn = build_conn(default_options)

      assert safe_to_string(HTML.from_conn(conn)) =~
               "<title>page</title>"
    end
  end

  defp build_conn(default_metatags \\ []) do
    defaults = Metatags.Plug.init(default_metatags)

    :get
    |> conn("/")
    |> Metatags.Plug.call(defaults)
  end

  defp safe_to_string(safe_string) do
    safe_string
    |> Safe.to_iodata()
    |> IO.iodata_to_binary()
  end
end
