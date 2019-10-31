defmodule AssignmentOne.RateLimiter do
  use GenServer

  defstruct [ rate: 5, queue: [] ]

  def start_link(request_second) do
    GenServer.start_link(__MODULE__, request_second, name: __MODULE__)
  end
  
  def init(request_second) do
    IO.puts("Initial call rate_limiter #{request_second}")
    state = %__MODULE__{ rate: request_second, queue: [] }
    send(self(), :tick)
    {:ok, state}
  end

  def handle_cast({:set_rate, new_rate}, state) do
    {:noreply, %{ state | rate: new_rate }}
  end

  def change_rate_limit(new_rate) do
    GenServer.cast(__MODULE__, { :set_rate, new_rate })
  end

  def handle_cast({:request_permission, pid}, state) do
    {:noreply, %{ state | queue: state.queue ++ [pid] }}
  end

  def request_permission(pid) do
    Genserver.cast(__MODULE__,{:request_permission, pid})
  end

  def handle_info(:tick, state = %__MODULE__{ queue: [] }) do
    Process.send_after(self(), :tick, 1000 / state.rate)
    {:noreply, state}
  end

  def handle_info(:tick, state = %__MODULE__{ queue: [x | xs] }) do
    Process.send(x, :permission_granted)
    Process.send_after(self(), :tick, 1000 / state.rate)
    {:noreply, %{state | queue: xs}}
  end
end
