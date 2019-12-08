defmodule Assignment.Logger do
  use GenServer

  def start_link(_) do
    IO.puts("Starting Logger")
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_cast({:log, level, message}, _state) do
    IO.puts("LOGGER: #{level} #{message}")
    {:noreply, nil}
  end

  def log(level, message) do
    GenServer.cast(__MODULE__, {:log, level, message})
  end
end
