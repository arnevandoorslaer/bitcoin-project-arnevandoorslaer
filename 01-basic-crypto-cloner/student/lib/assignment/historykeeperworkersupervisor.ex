defmodule Assignment.HistoryKeeperWorkerSupervisor do
  use DynamicSupervisor

  def start_link(_) do
    Assignment.Logger.log("", "Starting HistoryKeeperWorkerSupervisor")
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def start_child(pair) do
    spec = {Assignment.HistoryKeeperWorker, pair}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
