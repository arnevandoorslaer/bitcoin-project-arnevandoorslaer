defmodule AssignmentOne.Logger do
  use GenServer

  defstruct [ data: [] ]

  def start_link() do
    log("Starting Logger")
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def log(message) do
    GenServer.cast(__MODULE__, {:log, message})
  end

  def handle_cast({:log, message}, _state) do
    IO.puts("LOGGER: #{message}")
    {:noreply, nil}
  end
end
