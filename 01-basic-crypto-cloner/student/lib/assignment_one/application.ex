defmodule Assignment.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Assignment.Logger,[]},
      {Assignment.RateLimiter, []},
      {Assignment.HistoryKeeperWorkerSupervisor,[]},
      {Assignment.CoindataSupervisor,[]}
    ]
    opts = [strategy: :one_for_one, name: Assignment.Supervisor]
    Supervisor.start_link(children, opts)
  end
end