defmodule AssignmentOne.RateLimiter do
  use GenServer

  defstruct [ rate: 5, queue: [] ]

  def start_link(req_sec) do
    AssignmentOne.Logger.log("RateLimiter started")
    GenServer.start_link(__MODULE__, req_sec, name: __MODULE__)
  end

  def init(req_seq) do
    rate = req_seq.req_per_sec
    state = %__MODULE__{ rate: rate, queue: [] }
    send(self(), :tick)
    {:ok, state}
  end

  def change_rate_limit(new_rate) do
    GenServer.cast(__MODULE__, {:set_rate, new_rate})
  end

  def handle_cast({:set_rate, newRate}, state) do
    new_state = %{ state | rate: newRate }
    {:noreply, new_state}
  end

  def handle_cast({:request_permission, pid}, state) do
    new_state = %{ state | queue: state.queue ++ [pid] }
    {:noreply, new_state}
  end

  def request_permission(pid) do
    GenServer.cast(__MODULE__, {:request_permission, pid})
  end

  def handle_info(:tick, state = %__MODULE__{ queue: [] }) do
    rate = trunc(1000 / state.rate)
    Process.send_after(self(), :tick, rate)
    {:noreply, state}
  end

  def handle_info(:tick, state = %__MODULE__{ rate: r, queue: [x | xs] }) do
    send(x, :go)
    rate = trunc(1000 / r)
    Process.send_after(self(), :tick, rate)
    new_state = %{state | queue: xs}
    {:noreply, new_state}
  end
end
