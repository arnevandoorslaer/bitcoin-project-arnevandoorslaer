defmodule AssignmentOne.Startup do
  require IEx

  # This is just here to help you.
  # If you prefer another implementation, go ahead and change this (with the according startup callback)
  @from (DateTime.utc_now() |> DateTime.to_unix()) - 60 * 60 * 24 * 7
  @until DateTime.utc_now() |> DateTime.to_unix()

  defstruct from: @from, until: @until, req_per_sec: 5

  def start_link(args \\ []),
    do: {:ok, spawn_link(__MODULE__, :startup, [struct(__MODULE__, args)])}

  def startup(%__MODULE__{} = info) do
    # Implement this module
    # AssignmentOne.Logger.start_link()
    # Implement this module
    AssignmentOne.ProcessManager.start_link()
    # Implement this module
    AssignmentOne.RateLimiter.start_link(Map.from_struct(info))
    retrieve_coin_pairs() |> start_processes(info)

    keep_running_until_stopped()
  end

  defp retrieve_coin_pairs() do
    url = "https://poloniex.com/public?command=returnTicker"
    {:ok, response} = Tesla.get(url)
    parsed = response.body |> Jason.decode!()
    pairs = parsed |> Enum.map(fn {key,_value} -> key end)
  end

  defp start_processes(pairs, info) when is_list(pairs) do
    # IMPLEMENT
  end

  defp keep_running_until_stopped() do
    receive do
      :stop -> Process.exit(self(), :normal)
    end
  end
end
