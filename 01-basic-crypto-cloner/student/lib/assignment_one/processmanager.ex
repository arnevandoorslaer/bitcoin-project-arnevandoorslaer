defmodule AssignmentOne.ProcessManager do
  use GenServer

  defstruct [ data: [] ]

  def start_link() do
    GenServer.start_link(__MODULE__,
      :ok, name: __MODULE__)
  end

  def init(:ok) do
    state = %__MODULE__{data: []}
    {:ok, state}
  end

  def handle_call(:get_data, _sender , state) do
    {:reply, state.children, state}
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
end
