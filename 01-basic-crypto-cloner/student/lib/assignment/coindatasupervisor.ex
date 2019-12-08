defmodule Assignment.CoindataSupervisor do
  use Supervisor

  def start_link(_) do
    Assignment.Logger.log(:debug,"Starting CoindataSupervisor")
    Supervisor.start_link(__MODULE__,nil)
  end

  def init(_) do
    children = [
      {Assignment.ProcessManager, []},
      {DynamicSupervisor, strategy: :one_for_one, name: Assignment.CoindataRetrieverSupervisor}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
