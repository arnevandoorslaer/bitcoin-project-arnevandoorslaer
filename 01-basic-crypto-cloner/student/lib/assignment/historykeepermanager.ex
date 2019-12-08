defmodule Assignment.HistoryKeeperManager do
  use GenServer
  defstruct data: []

  def start_link(info) do
    Assignment.Logger.log("", "Starting HistoryKeeperManager")
    GenServer.start_link(__MODULE__, info, name: __MODULE__)
  end

  def init(info) do
    state = %__MODULE__{data: info}
    {:ok, state, {:continue, :add_pair}}
  end

  def handle_call({:get_pid_for, pair}, _, state) do
    {_, pid} = state.data |> List.keyfind(pair, 0)
    {:reply, pid, state}
  end

  def handle_call(:retrieve_history, _, state) do
    {:reply, state.data, state}
  end

  def handle_cast({:add_pair, pair, pid}, state) do
    {:noreply, %{state | data: List.flatten(state.data ++ [{pair, pid}])}}
  end

  def handle_continue(:add_pair, state) do
    pairs = Assignment.ProcessManager.retrieve_coin_pairs()
    Enum.each(pairs, fn pair ->
      {:ok, pid} = Assignment.HistoryKeeperWorkerSupervisor.start_child(pair)
      add_key_value(pid, pair)
    end)
    {:noreply, state}
  end

  def get_pid_for(pair) do
    GenServer.call(__MODULE__, {:get_pid_for, pair})
  end

  def retrieve_history_processes() do
    GenServer.call(__MODULE__, :retrieve_history)
  end

  def add_key_value(pid, pair) do
    GenServer.cast(__MODULE__, {:add_pair, pair, pid})
  end
end
