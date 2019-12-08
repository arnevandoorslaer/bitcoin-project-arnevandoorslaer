defmodule Assignment.HistoryKeeperSupervisor do
  use Supervisor

  def start_link(_) do
    Assignment.Logger.log("","Starting HistoryKeeperSupervisor")
    Supervisor.start_link(__MODULE__,nil)
  end

  def init(_) do
    children = [
      {Assignment.HistoryKeeperManager, []},
      {DynamicSupervisor, strategy: :one_for_one, name: Assignment.HistoryKeeperWorkerSupervisor}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
