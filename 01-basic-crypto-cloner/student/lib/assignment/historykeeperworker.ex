defmodule Assignment.HistoryKeeperWorker do
  use GenServer
  defstruct [history: [], frames: [], pair: nil]

  def start_link(pair) do
    GenServer.start_link(__MODULE__, pair)
  end

  def init(pair) do
    from = Application.get_env(:assignment, :from)
    until = Application.get_env(:assignment, :until)

    state = %__MODULE__{pair: pair, history: [], frames: [{from, until}]}
    {:ok, state}
  end

  def handle_call(:request_frame, _, state) do
    new_frames = List.delete_at(state.frames, 0)
    {:reply, List.first(state.frames), %{state | frames: new_frames}}
  end

  def handle_call(:get_history,_,state) do
    {:reply, {state.pair, state.history}, state}
  end

  def handle_call(:get_pair_info, _, state) do
    {:reply, state.pair, state}
  end

  def handle_cast(:delete_frame,state) do
    {:noreply, List.first(state.frames), %{state | frames: List.delete_at(state.frames, 0)}}
  end

  def handle_cast({:add_history, new_history}, state) do
    {:noreply, %{state | history: state.history ++ new_history}}
  end

  def handle_cast({:split_frame,start_frame, end_frame}, state) do
    middle = trunc(start_frame + trunc(end_frame - start_frame) / 2)
    first = {start_frame,middle}
    second = {middle,end_frame}
    new_frames = List.delete_at(state.frames, 0)
    {:noreply, %{state | frames: List.flatten([new_frames] ++ [first,second])}}
  end

  def request_frame(pair) do
    GenServer.call(Assignment.HistoryKeeperManager.get_pid_for(pair), :request_frame)
  end

  def get_history(pid) do
    GenServer.call(pid, :get_history)
  end

  def get_pair_info(pid) when is_pid(pid) do
    GenServer.call(pid, :get_pair_info)
  end

  def delete_frame(pair) do
    GenServer.cast(Assignment.HistoryKeeperManager.get_pid_for(pair), :delete_frame)
  end

  def add_history(pair, new_history) do
    GenServer.cast(Assignment.HistoryKeeperManager.get_pid_for(pair),{:add_history, new_history})
  end

  def split_frame({start_frame,end_frame,pair}) do
    GenServer.cast(Assignment.HistoryKeeperManager.get_pid_for(pair), {:split_frame,start_frame,end_frame})
  end
end
