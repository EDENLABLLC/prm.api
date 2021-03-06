defmodule PRM.Web.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  @header_consumer_id "x-consumer-id"

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      import PRM.Web.Router.Helpers

      # The default endpoint for testing
      @endpoint PRM.Web.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(PRM.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(PRM.Repo, {:shared, self()})
    end

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> put_client_id(tags[:without_consumer_id])

    {:ok, conn: conn}
  end

  defp put_client_id(conn, true), do: conn
  defp put_client_id(conn, _), do: Plug.Conn.put_req_header(conn, @header_consumer_id, Ecto.UUID.generate())
end
