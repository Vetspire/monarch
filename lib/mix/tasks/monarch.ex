defmodule Mix.Tasks.Monarch do
  @shortdoc "Creates a skeleton file that implements the monarch behaviour."

  @moduledoc """
  The monarch mix task: `mix help monarch`
  """

  use Mix.Task

  import Macro, only: [camelize: 1]
  import Mix.Generator

  @switches [
    monarch_path: :string
  ]

  @impl Mix.Task
  def run(args) do
    case OptionParser.parse!(args, switches: @switches) do
      {opts, [base_name]} ->
        path = opts[:monarch_path]

        module_path =
          if path do
            split_string_list = String.split(path, "lib/")

            split_string_list
            |> List.last()
            |> camelize()
          else
            Mix.raise("expected to receive a monarch_path argument")
          end

        app_dir = File.cwd!()
        file_name = "#{base_name}.ex"
        file = Path.join([app_dir, path, file_name])
        unless File.dir?(path), do: create_directory(path)

        # credo:disable-for-lines:1
        assigns = [mod: Module.concat([module_path, camelize(base_name)])]
        create_file(file, monarch_template(assigns))

      {_, _} ->
        Mix.raise("expected to receive a file name, got: #{inspect(Enum.join(args, " "))}")
    end
  end

  embed_template(:monarch, """
  defmodule <%= inspect @mod %> do
    @behaviour Monarch

    @impl Monarch
    def skip, do: false

    @impl Monarch
    def scheduled_at, do: DateTime.utc_now()

    @impl Monarch
    def query do
      # A query that returns a chunk of records that still need to be updated
      []
    end

    @impl Monarch
    def update(_records_returned_from_query) do
      # A function that runs an update or processes the chunk of `records_returned_from_query`
    end
  end
  """)
end
