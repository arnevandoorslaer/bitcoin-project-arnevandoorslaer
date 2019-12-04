defmodule Assignment.ProcessManager do
  use GenServer

  defstruct [ data: [] ]

  def start_link() do
    AssignmentOne.Logger.log("Starting processmanager")
    GenServer.start_link(__MODULE__,
      :ok, name: __MODULE__)
  end

  def init(:ok) do
    state = %__MODULE__{data: []}
    {:ok, state}
  end

  def handle_call(:get_data, _sender , state) do
    {:reply, state.data, state}
  end

  def retrieve_coin_processes() do
    GenServer.call(__MODULE__, :get_data)
  end

  def handle_cast({:add_pid, {coin_pair, pid}}, state) do
    {:noreply, %{ state | data: state.data ++ [{coin_pair, pid}] }}
  end

  def add_entry(coin_pair, pid) do
    GenServer.cast(__MODULE__, {:add_pid, {coin_pair, pid}})
  end

  def handle_continue(:add_pair, state) do
    pairs = retrieve_coin_pairs()
    Enum.each(pairs, fn pair -> Assignment.CoindataRetrieverSupervisor.start_child(pair) end)
    {:noreply, state}
  end

  def retrieve_coin_pairs() do
    url = "https://poloniex.com/public?command=returnTicker"
    {:ok, response} = Tesla.get(url)
    parsed = response.body |> Jason.decode!()
    parsed |> Enum.map(fn {key, _value} -> key end)
  end
end
