defmodule Assignment.HistoryKeeperWorkerSupervisor do

  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    children = [
      { DynamicSupervisor, strategy: :one_for_one, name: Assignment.HistoryKeeperSupervisor},
      { Assignment.HistoryKeeperManager, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

end