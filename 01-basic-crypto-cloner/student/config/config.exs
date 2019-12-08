use Mix.Config

config :assignment,
  from: (DateTime.utc_now() |> DateTime.to_unix()) - 3600 * 24,
  until: (DateTime.utc_now() |> DateTime.to_unix()),
  rate: 5

