defmodule Assignment.ProcessManager do
  use GenServer
  defstruct data: []

  def start_link(_) do
    Assignment.Logger.log(:debug, "Starting ProcessManager")
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    state = %__MODULE__{data: []}
    {:ok, state, {:continue, :add_pair}}
  end

  def handle_call(:get_data, _, state) do
    {:reply, state.data, state}
  end

  def handle_cast({:add_pid, {coin_pair, pid}}, state) do
    {:noreply, %{state | data: state.data ++ [{coin_pair, pid}]}}
  end

  def handle_continue(:add_pair, state) do
    Assignment.Logger.log(:debug, "Continue ProcessManager")
    pairs = retrieve_coin_pairs()

    Enum.each(pairs, fn pair ->
      {_, pid} = Assignment.CoindataRetrieverSupervisor.start_child(pair)
      add_entry(pair, pid)
    end)

    {:noreply, state}
  end

  def retrieve_coin_processes do
    data = GenServer.call(__MODULE__, :get_data)
    if length(data) == 0 do
      retrieve_coin_processes()
    else
      data
    end
  end

  def add_entry(pair, pid) do
    GenServer.cast(__MODULE__, {:add_pid, {pair, pid}})
  end

  def retrieve_coin_pairs() do
    Assignment.Logger.log(:debug, "Retrieving coinpairs in ProcessManager")
    url = 'https://poloniex.com/public?command=returnTicker'
    {:ok, response} = Tesla.get(url)
    parsed = response.body |> Jason.decode!()
    parsed |> Enum.map(fn {key, _value} -> key end)
  end
end
