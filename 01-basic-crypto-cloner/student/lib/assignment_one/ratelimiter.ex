defmodule AssignmentOne.RateLimiter do
  use GenServer

  defstruct [ rate: 5, queue: [] ]

  def start_link(info) do
    AssignmentOne.Logger.log("Starting ratelimiter")
    GenServer.start_link(__MODULE__, info, name: __MODULE__)
  end

  def init(info) do
    state = %__MODULE__{ rate: info.req_per_sec, queue: [] }
    send(self(), :tick)
    {:ok, state}
  end

  def change_rate_limit(new_rate) do
    GenServer.cast(__MODULE__, { :set_rate, new_rate })
  end

  def handle_cast({:set_rate, new_rate}, state) do
    {:noreply, %{ state | rate: new_rate }}
  end

  def handle_cast({:request_permission, pid}, state) do
    {:noreply, %{ state | queue: state.queue ++ [pid] }}
  end

  def request_permission(pid) do
    GenServer.cast(__MODULE__,{:request_permission, pid})
  end

  def handle_info(:tick, state = %__MODULE__{ queue: [] }) do
    Process.send_after(self(), :tick, trunc(1000 / state.rate))
    {:noreply, state}
  end

  def handle_info(:tick, state = %__MODULE__{ queue: [x | xs] }) do
    send(x, :go)
    Process.send_after(self(), :tick, trunc(1000 / state.rate))
    {:noreply, %{state | queue: xs}}
  end
end
