defmodule AssignmentOne.CoindataRetriever do

  use GenServer

  defstruct []

  def start_link() do
    GenServer.start_link(__MODULE__)
  end

  def init(request_second) do
    IO.puts("Initial call rate_limiter #{request_second}")
    state = %__MODULE__{ rate: request_second, queue: [] }
    send(self(), :tick)
    {:ok, state}
  end

  def get_history(PID) when is_pid(pid) do

  end
end
