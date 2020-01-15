defmodule Reporter.Application do
  use Application

  def start(_type, _args) do
    topologies = [
      topology: [
        # The selected clustering strategy. Required.
        strategy: Cluster.Strategy.Epmd,
        # Configuration for the provided strategy. Optional.
        config: [hosts: [:a@localhost, :b@localhost, :c@localhost, :reporter@localhost]],
        # The function to use for connecting nodes. The node
        # name will be appended to the argument list. Optional
        connect: {:net_kernel, :connect_node, []},
        # The function to use for disconnecting nodes. The node
        # name will be appended to the argument list. Optional
        disconnect: {:erlang, :disconnect_node, []},
        # The function to use for listing nodes.
        # This function must return a list of node names. Optional
        list_nodes: {:erlang, :nodes, [:connected]},
      ]
    ]

    children = [
      {Cluster.Supervisor, [topologies, [name: Assignment.ClusterSupervisor]]},
      {Reporter.Reporter, []}
    ]

    opts = [strategy: :one_for_one, name: Reporter.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
