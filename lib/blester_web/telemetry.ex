defmodule BlesterWeb.Telemetry do
  @moduledoc """
  Telemetry supervisor for handling metrics collection and reporting.
  """
  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Add reporters as children of your supervision tree.
      # {TelemetryMetricsPrometheus, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
