defmodule Assignment.CoindataCoordinator do
  use GenServer
  use Tesla

  defstruct data: nil

  def start_link(_) do
    GenServer.start_link(__MODULE__,nil, name: {:via, :global, {Node.self(), __MODULE__}})
  end

  def init(_) do
    state = %__MODULE__{data: retrieve_coin_pairs()}
    {:ok, state, {:continue, :continue}}
  end
  def handle_continue(:continue, state) do
    if(is_first_node?()) do
      Enum.each(state.data, fn pair -> Assignment.HistoryKeeperWorkerSupervisor.start_child(pair) end)
      Enum.each(state.data, fn pair -> Assignment.CoindataRetrieverSupervisor.start_child(pair) end)
    end
    {:noreply, state}
  end

  def handle_call(:reg_key_from_node,_,state) do
    keys = retrieve_all_registry_keys()
    {:reply, keys,state}
  end

  def handle_call({:get_pid_for,pair},_,state) do
    [{pid, _value}] = Registry.lookup(Assignment.HistoryKeeper.Registry, pair)
    {:reply, pid, state}
  end

  def balance() do
    Enum.each(get_all_nodes(), fn x ->
      Enum.each(filter_out_reporter(Node.list), fn y ->
        keys = retrieve_all_registry_keys_from_node(x)
        amount = length(keys) - get_pairs_per_node()
        diff = Enum.take(keys, -amount)
        Enum.each(diff, fn { pair, _} ->
          if (length(retrieve_all_registry_keys_from_node(y)) < get_pairs_per_node()) do
            transfer_pair_at_node(y, pair)
            :timer.sleep(100)
          end
        end)
      end)
    end)
  end

  def get_pid_for(pair) do
    GenServer.call(get_self_pid(),{:get_pid_for,pair})
  end

  def retrieve_coin_pairs() do
    url = 'https://poloniex.com/public?command=returnTicker'
    {:ok, response} = Tesla.get(url)
    parsed = response.body |> Jason.decode!()
    parsed |> Enum.map(fn {key, _value} -> key end)
  end

  def get_all_nodes() do
    filter_out_reporter([node() | Node.list()])
  end

  def is_first_node?() do
    length(get_all_nodes()) == 1
  end

  def transfer_pairs(amount, list, node) do
    Enum.each(Enum.take(list, -amount), fn pair ->
      {pair_value, _pid} = pair
      transfer_pair_at_node(node, pair_value)
    end)
  end

  #example
  #Assignment.CoindataCoordinator.transfer_pair_at_node(:b@localhost,"USDC_USDT")
  def transfer_pair_at_node(dest_node, pair) do
      historykeeper_pid = get_pid_for(pair)
      {_, history} = GenServer.call(historykeeper_pid, :get_history)
      frames = GenServer.call(historykeeper_pid, :get_frames)
      Node.spawn_link(dest_node, fn -> Assignment.HistoryKeeperWorkerSupervisor.start_child(pair, history, frames) end)
      Node.spawn_link(dest_node, fn -> Assignment.CoindataRetrieverSupervisor.start_child(pair) end)
      Assignment.CoindataRetriever.stop(pair)
      Assignment.HistoryKeeperWorker.stop(pair)
  end
  def retrieve_all_registry_keys(), do: Registry.select(Assignment.HistoryKeeper.Registry, [{{:"$1", :"$2", :_}, [], [{{:"$1", :"$2"}}]}])
  def retrieve_all_registry_keys_from_node(node) do
    pid = :global.whereis_name({node, Assignment.CoindataCoordinator})
    if(pid == get_self_pid()) do
      retrieve_all_registry_keys()
    else
      GenServer.call(pid, :reg_key_from_node)
    end
  end

  def get_self_pid() do
    :global.whereis_name({node(), Assignment.CoindataCoordinator})
  end

  def get_pairs_per_node() do
    nodes = get_all_nodes()
    trunc(Enum.sum(Enum.map(nodes, fn node -> length(retrieve_all_registry_keys_from_node(node)) end)) / length(nodes))
  end

  def filter_out_reporter(list) do
    Enum.map(list,fn node ->
      if !String.contains?(Atom.to_string(node), "reporter") do
        node
      end
    end)
  end
end
