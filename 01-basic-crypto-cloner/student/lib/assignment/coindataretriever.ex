defmodule Assignment.CoindataRetriever do
  use GenServer
  use Tesla
  defstruct pair: nil

  def start_link(pair) do
    GenServer.start_link(__MODULE__, pair)
  end

  def init(pair) do
    state = %__MODULE__{pair: pair}
    send(self(), :request_permission)
    {:ok, state}
  end

  def handle_info(:request_permission, state) do
    Assignment.RateLimiter.request_permission(self())
    {:noreply, state}
  end

  def handle_info(:go, state) do
    result = Assignment.HistoryKeeperWorker.request_frame(state.pair)
    if(result != nil) do
      {start_frame, end_frame} = result
      url ="https://poloniex.com/public?command=returnTradeHistory&currencyPair=#{state.pair}&start=#{start_frame}&end=#{end_frame}"
      {:ok, response} = Tesla.get(url)
      parsed = response.body |> Jason.decode!()
      if(length(parsed) >= 999) do
        Assignment.HistoryKeeperWorker.split_frame({start_frame,end_frame,state.pair})
        send(self(), :request_permission)
        {:noreply, state}
      else
        if (parsed != nil) do
          Assignment.HistoryKeeperWorker.add_history(state.pair,parsed)
        end
        Assignment.Logger.log("","CoindataRetriever requested coin history: #{state.pair}, start: #{inspect(start_frame)}, end: #{inspect(end_frame)} at #{inspect(:calendar.universal_time())}")
        send(self(), :request_permission)
        {:noreply, state}
      end
    else
      {:noreply, state}
    end
  end
end
