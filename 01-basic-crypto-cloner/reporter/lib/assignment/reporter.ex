defmodule Reporter.Reporter do
  use GenServer

  defstruct [from: Application.get_env(:assignment, :from),until: Application.get_env(:assignment, :until)]

  def start_link(_) do
    GenServer.start_link(__MODULE__,nil,name: __MODULE__)
  end

  def init(_) do
    state = %__MODULE__{}
    {:ok, state, {:continue, :continue}}
  end

  def handle_continue(:continue, state) do
    :timer.sleep(1000)
    retrieve_all_coin_pairs()
    {:noreply, state}
  end

  def handle_cast(:retrieve,state) do
    total_duration = state.until - state.from
    list = List.flatten(Enum.map(Node.list(),fn node->
      pid = :global.whereis_name({node, Assignment.CoindataCoordinator})
      keys = GenServer.call(pid, :reg_key_from_node)
      Enum.map(keys,fn pair ->
        {pairname,pid} = pair
        {_,history} = GenServer.call(pid, :get_history)
        frames = GenServer.call(pid,  :get_frames)
        duration_to_go = get_percent_helper(frames)
        percentage = trunc(((total_duration - duration_to_go) / total_duration) * 100)
        {node,pairname,length(history),percentage}
      end)
    end))
    IO.puts " "
    IO.puts "node | pair | history | percentage"
    Enum.each(list,fn {node,pair,history,percentage} ->
      node_out = check_node_name(node)
      pair_out = parse_pair(pair)
      history_out = history
      percentage_out = parse_percentage(Integer.to_string(percentage))
      progress_out = parse_percent(get_percent_output(percentage))
      IO.puts("#{inspect(node_out)} | #{inspect(pair_out)} | #{inspect(progress_out)} | #{inspect(percentage_out)} | #{inspect(history_out)}")
    end)
    {:noreply,state}
  end

  def retrieve_all_coin_pairs() do
    GenServer.cast(self(),:retrieve)
  end

  def get_percent_helper(frames) do
    if(length(frames) < 1) do
      0
    else
      [head | tail] = frames
      {from, until} = head
      duration = until - from
      duration + get_percent_helper(tail)
    end
  end

  def check_node_name(node) do
    string_name = Atom.to_string(node)
    {first,_} = String.split(string_name, "") |> List.pop_at(1)
    "N" <> String.upcase(first)
  end

  def parse_pair(pair) do
    if String.length(pair) < 11 do
      parse_pair(pair <> " ")
    else
      pair
    end
  end

  def parse_percentage(percentage) do
    if String.length(percentage) < 3 do
      parse_percentage(percentage <> " ")
    else
      percentage
    end
  end

  def get_percent_output(percent) do
    if percent < 5 do
      ""
    else
      "x" <> get_percent_output(percent - 5)
    end
  end

  def parse_percent(percentage) do
    if String.length(percentage) < 20 do
      parse_percent(percentage <> "-")
    else
      percentage
    end
  end
end
