defmodule Premailex.HTTPAdapter do
  @moduledoc """
  HTTP client adapter behaviour.

  ## Usage

      defmodule MyHTTPAdapter do
        @behaviour Premailex.HTTPAdapter

        @impl true
        def request(method, url, body, headers, opts) do
          # Implement your HTTP request logic here using your preferred HTTP client library.
          # Return {:ok, response} or {:error, reason}.
        end
      end

  Then, configure Premailex to use your custom adapter:

      config :premailex,
        http_adapter: MyHTTPAdapter
  """

  defmodule HTTPResponse do
    @moduledoc false

    @type header :: {binary(), binary()}
    @type t :: %__MODULE__{
            status: integer(),
            headers: [header()],
            body: binary()
          }

    defstruct status: 200, headers: [], body: ""
  end

  @type method :: :get | :post
  @type body :: binary() | nil
  @type headers :: [{binary(), binary()}]

  @callback request(method(), binary(), body(), headers(), Keyword.t()) ::
              {:ok, map()} | {:error, any()}

  @spec user_agent_header() :: {binary(), binary()}
  def user_agent_header do
    version = Application.spec(:premailex, :vsn) || "0.0.0"

    {"User-Agent", "Premailex-#{version}"}
  end
end
