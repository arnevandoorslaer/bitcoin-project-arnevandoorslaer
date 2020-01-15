defmodule Assignment.HistoryKeeperWorker do
  use GenServer, restart: :transient
  defstruct [history: [], frames: [{ Application.get_env(:assignment, :from), Application.get_env(:assignment, :until)}], pair: nil]

  def start_link(args) when is_list(args) do
    pair = args[:pair]
    GenServer.start_link(__MODULE__, args, name: {:via, Registry, {Assignment.HistoryKeeper.Registry, pair}})
  end

  def start_link(pair) do
    GenServer.start_link(__MODULE__, [pair: pair, history: [], frames: [{ Application.get_env(:assignment, :from), Application.get_env(:assignment, :until)}]], name: {:via, Registry, {Assignment.HistoryKeeper.Registry, pair}})
  end

  def init(args) do
    state = struct(__MODULE__,[pair: args[:pair],history: args[:history],frames: args[:frames]])
    if(above_one_month?(state.frames)) do
      {from,until} = List.first(state.frames)
      months = ceil((until-from) / (60*60*24*30))
      width = ceil((until-from) / months)
      {:ok, %{state | frames: divide_frames(from,months,width)}}
    else
      {:ok, state}
    end
  end

  def stop(pair), do: GenServer.stop(via_tuple(pair), :normal)
  defp via_tuple(pid) when is_pid(pid), do: pid
  defp via_tuple(name), do: {:via, Registry, {Assignment.HistoryKeeper.Registry, name}}

  def handle_info(:frame_check, state) do
    if(above_one_month?(state.frames)) do
      {from,until} = List.first(state.frames)
      months = ceil((until-from) / (60*60*24*30))
      width = ceil((until-from) / months)
      {:noreply, %{state | frames: divide_frames(from,months,width)}}
    else
      {:noreply, state}
    end
  end

  def divide_frames(start,counter,width) do
    if (counter < 1) do
      []
    else
      List.flatten([{floor(start + ((counter-1) * width)),ceil(start + (counter * width))}] ++ divide_frames(start,counter-1,width))
    end
  end

  def above_one_month?(frames) do
    Enum.any?(frames, fn {from, until} -> until - from >= 60*60*24*30 end)
  end

  def handle_call(:request_frame, _, state) do
    new_frames = List.delete_at(state.frames, 0)
    {:reply, List.first(state.frames), %{state | frames: new_frames}}
  end

  def handle_call(:get_frames,_,state) do
    {:reply, state.frames, state}
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
    {:noreply, %{state | frames: List.flatten([state.frames] ++ [first,second])}}
  end

  def request_frame(pair) do
    GenServer.call(Assignment.CoindataCoordinator.get_pid_for(pair), :request_frame)
  end

  def get_history(pid) do
    GenServer.call(pid, :get_history)
  end

  def get_pair_info(pid) when is_pid(pid) do
    GenServer.call(pid, :get_pair_info)
  end

  def delete_frame(pair) do
    GenServer.cast(Assignment.CoindataCoordinator.get_pid_for(pair), :delete_frame)
  end

  def add_history(pair, new_history) do
    GenServer.cast(Assignment.CoindataCoordinator.get_pid_for(pair),{:add_history, new_history})
  end

  def split_frame({start_frame,end_frame,pair}) do
    GenServer.cast(Assignment.CoindataCoordinator.get_pid_for(pair), {:split_frame,start_frame,end_frame})
  end
end
