defmodule PlugHelper do

  defmacro __using__(_opts) do
    quote do
      use Plug.Test

      @session Plug.Session.init(
        store: :cookie,
        key: "_app",
        encryption_salt: "yadayada",
        signing_salt: "yadayada"
      )

      def request(http_method, path, params \\ nil) do
        conn = conn(http_method, path, params)
        |> Map.put(:secret_key_base, String.duplicate("abcdefgh", 8))
        |> Plug.Conn.put_private(:plug_skip_csrf_protection, true)
        |> Plug.Session.call(@session)
        |> Plug.Conn.fetch_params
        Blog.Router.call(conn, [])
      end
    end
  end
end
