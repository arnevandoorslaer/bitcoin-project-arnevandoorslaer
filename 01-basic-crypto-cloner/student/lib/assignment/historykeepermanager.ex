defmodule Assignment.HistoryKeeperManager do
  use GenServer

  defstruct [ pids: [] ]

  def start_link(info) do
    GenServer.start_link(__MODULE__, info, name: __MODULE__)
  end

  def init(info) do
    state = %__MODULE__{pids: info}

    {:ok, state, {:continue, :manage}}
  end


  def add_key_value(pid, pair) do
    Assignment.Logger.log("#{inspect pid} & #{inspect pair}")
    GenServer.cast(self(), {:add_to_list, {pair, pid}})
  end


  def get_pid_for(pair) do
    Assignment.Logger.log("#{inspect pair}")
    GenServer.call(__MODULE__, {:get_pid, pair})
  end

  def retrieve_history_processes() do
    GenServer.call(__MODULE__, :map_history)
  end

  def handle_continue(:manage, state) do
    list_pairs = Assignment.ProcessManager.retrieve_coin_pairs()

    Enum.each(list_pairs, fn pair ->
      {:ok, pid} = Assignment.HistoryKeeperSupervisor.start_child(pair)
      add_key_value(pid, pair)
    end)
    {:noreply, state}
  end

  def handle_cast({:add_to_list, {pair, pid}}, state) do
    new_state = %{ state | pids: state.pids ++ [{pair, pid}]}
    {:noreply, new_state}
  end

  def handle_call(:map_history, _from ,state) do
    {:reply, state.pids, state}
  end

  def handle_call({:get_pid, pair}, _from ,state) do
    result = get_pid(pair, state)
    {:reply, result, state}
  end

  defp get_pid(pair, state) do
    Enum.each(state.pids, fn {p, pid} ->
      if p == pair do
        Assignment.Logger.log("#{inspect pid}")
        pid
      end
    end )
  end
end
