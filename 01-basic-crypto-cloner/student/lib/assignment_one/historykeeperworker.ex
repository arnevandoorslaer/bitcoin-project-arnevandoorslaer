defmodule Assignment.HistoryKeeperWorker do
  use GenServer

  defstruct [pair: nil, history: [], from: Application.get_env(:assignment, :from) , until: Application.get_env(:assignment, :until), timeframe: 3600 * 24]

  def start_link(pair) do
    GenServer.start_link(__MODULE__, pair)
  end

  def init(pair) do
    state = struct(__MODULE__, pair)
    {:ok, state}
  end

  def handle_call(:history, _from,state) do
    {:reply, {state.pair, state.history}, state}
  end

  def handle_call(:info, _from ,state) do
    {:reply, state.pair, state}
  end

  def handle_call(:request_time, _from ,state) do
    {:reply, %{from: state.from, until: state.until}, state}
  end

  def get_history(pid) do
    GenServer.call(pid, :history)
  end

  def get_pair_info(pair) do 
    GenServer.call(Assignment.HistoryKeeperManager.get_pid_for(pair), :info)
  end

  def request_timeframe(pair) do
    GenServer.call(Assignment.HistoryKeeperManager.get_pid_for(pair), :request_time)
  end
end
