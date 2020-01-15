defmodule Assignment.HistoryKeeperSupervisor do
  use Supervisor

  def start_link(_) do
    #Assignment.Logger.log(:info,"Starting HistoryKeeperSupervisor")
    Supervisor.start_link(__MODULE__,nil)
  end

  def init(_) do
    children = [
      {Registry, keys: :unique, name: Assignment.HistoryKeeper.Registry},
      {DynamicSupervisor, strategy: :one_for_one, name: Assignment.HistoryKeeperWorkerSupervisor}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
