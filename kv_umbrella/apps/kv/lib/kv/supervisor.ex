defmodule KV.Supervisor do
  @moduledoc """
  The supervisor module for our key-value store.
  """

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      {DynamicSupervisor, name: KV.BucketSupervisor, strategy: :one_for_one},
      {KV.Registry, name: KV.Registry},
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end