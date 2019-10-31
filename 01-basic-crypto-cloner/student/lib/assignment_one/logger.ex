defmodule AssignmentOne.Logger do
  use GenServer

  defstruct [ data: [] ]
  
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    state = %__MODULE__{data: []}
    {:ok, state}
  end

  def log(message) do
    GenServer.cast(__MODULE__, {:log, message})
  end

  def handle_cast({:log, pid, message}, state) do
    IO.puts("pid: #{inspect pid} with message: #{message}")
    {:noreply, state}
  end
end
