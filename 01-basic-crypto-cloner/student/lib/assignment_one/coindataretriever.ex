defmodule AssignmentOne.CoindataRetriever do
  use GenServer
  use Tesla

  defstruct pair: {}, history: [], from: {}, until: {}

  def start(pair, from, until) do
    AssignmentOne.Logger.log("Retrieving #{pair}")
    GenServer.start(__MODULE__, {pair, from, until})
  end

  def init({pair, from, until}) do
    AssignmentOne.RateLimiter.request_permission(self())
    AssignmentOne.ProcessManager.add_entry(pair, self())
    state = %__MODULE__{ pair: pair, history: [], from: from, until: until }
    {:ok, state}
  end

  def handle_info(:go, state) do
    AssignmentOne.RateLimiter.request_permission(self())
    history = retrieve_pair_history(state.pair, state.from, state.until)
    from = state.from - 1800
    until = state.until
    {:noreply, %{state | history: history, from: from, until: until}}
  end

  def retrieve_pair_history(pair, from, until) do
    url = "https://poloniex.com/public?command=returnTradeHistory&currencyPair=#{pair}&start=#{inspect(from)}&end=#{inspect(until)}"
    AssignmentOne.Logger.log("Retrieved coin at #{inspect(:calendar.universal_time())} | coin: #{pair}, start: #{inspect(from)}, end: #{inspect(until)}")
    {:ok, response} = Tesla.get(url)
    response.body |> Jason.decode!()
  end

  def get_history(pid) do
    GenServer.call(pid, :history)
  end

  def handle_call(:history, _from, state) do
    {:reply, {state.pair, state.history}, state}
  end
end
