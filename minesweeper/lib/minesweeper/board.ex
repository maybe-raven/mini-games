defmodule Minesweeper.Board do
  alias Minesweeper.Board.Grid
  alias Minesweeper.Board
  alias Minesweeper.Board.Tile

  @type state :: :new | :ok | :loss | :win
  @type t :: %Board{
          grid: Grid.grid(),
          width: Grid.width(),
          height: Grid.height(),
          highlighted_points: [Grid.point()],
          mark_count: non_neg_integer(),
          bomb_count: pos_integer(),
          state: state()
        }
  @derive {Inspect, only: [:width, :height, :state]}
  defstruct [
    :grid,
    :width,
    :height,
    :bomb_count,
    mark_count: 0,
    highlighted_points: [],
    state: :new
  ]

  @type difficulty :: :easy | :medium | :hard
  @type config :: %{width: Grid.width(), height: Grid.height(), bomb_count: pos_integer()}

  # region Constructors

  @spec new_with_difficulty(difficulty()) :: t()
  def new_with_difficulty(difficulty),
    do: difficulty |> config_for_difficulty |> new_with_config()

  @spec new_with_config(config()) :: t()
  def new_with_config(%{width: width, height: height, bomb_count: bomb_count}) do
    %Board{
      grid: Grid.new(width, height, bomb_count),
      width: width,
      height: height,
      bomb_count: bomb_count
    }
  end

  @spec config_for_difficulty(difficulty()) :: config()
  defp config_for_difficulty(:easy), do: %{width: 10, height: 10, bomb_count: 10}
  defp config_for_difficulty(:medium), do: %{width: 20, height: 20, bomb_count: 50}
  defp config_for_difficulty(:hard), do: %{width: 40, height: 20, bomb_count: 200}

  # endregion

  # region Transformers for Input Events

  @spec toggle_mark_tile(t(), Grid.point()) :: t()
  def toggle_mark_tile(%Board{grid: grid} = board, point) do
    tile = Grid.get_tile(grid, point) |> Tile.toggle_mark()

    %{
      board
      | grid: Grid.set_tile(grid, tile),
        mark_count: mark_count(board, tile.state),
        state: :ok
    }
  end

  defp mark_count(%Board{mark_count: count}, :marked), do: count + 1
  defp mark_count(%Board{mark_count: count}, :normal), do: count - 1
  defp mark_count(%Board{mark_count: count}, _), do: count

  @spec highlight_tile(t(), Grid.point()) :: t()
  def highlight_tile(%Board{highlighted_points: highlighted_points, grid: grid} = board, point),
    do: %{
      board
      | grid:
          grid
          |> Grid.update_tiles(highlighted_points, &Tile.remove_highlight/1)
          |> Grid.update_tile(point, &Tile.highlight/1),
        highlighted_points: [point],
        state: :ok
    }

  @spec highlight_block(t(), Grid.point()) :: t()
  def highlight_block(
        %{
          width: width,
          height: height,
          grid: grid,
          highlighted_points: highlighted_points
        } = board,
        point
      ) do
    block = Grid.get_adjacent_points(width, height, point)

    %{
      board
      | grid:
          grid
          |> Grid.update_tiles(highlighted_points, &Tile.remove_highlight/1)
          |> Grid.update_tiles(block, &Tile.highlight/1),
        highlighted_points: block,
        state: :ok
    }
  end

  @spec remove_highlights(t()) :: t()
  def remove_highlights(%Board{highlighted_points: []} = board), do: board

  def remove_highlights(%Board{grid: grid, highlighted_points: highlighted_points} = board) do
    %{
      board
      | grid: Grid.update_tiles(grid, highlighted_points, &Tile.remove_highlight/1),
        highlighted_points: []
    }
  end

  @spec reveal_tile(t(), Grid.point()) :: t()
  def reveal_tile(%Board{grid: grid} = board, point) do
    {loss?, grid} = Grid.reveal_tiles(grid, [Grid.get_tile(grid, point)])
    %{board | grid: grid, state: game_state(grid, loss?), highlighted_points: []}
  end

  @spec reveal_block(t(), Grid.point()) :: t()
  def reveal_block(board, point) do
    %Board{grid: grid} = board = remove_highlights(board)
    tile = Grid.get_tile(grid, point)

    if tile.state == :revealed do
      block = Grid.get_block(grid, point)
      marked_neighbor_count = Enum.count(block, &(&1.state == :marked))

      if marked_neighbor_count == tile.bomb_count do
        {loss?, grid} = Grid.reveal_tiles(grid, block)
        %{board | grid: grid, state: game_state(grid, loss?), highlighted_points: []}
      else
        board
      end
    else
      board
    end
  end

  def reveal_tile_0(%Board{grid: grid} = board, point) do
    %{board | highlighted_points: []}
    |> reveal_tiles_0([Grid.get_tile(grid, point)])
  end

  def reveal_tiles_0(board, tiles)
  def reveal_tiles_0(board, []), do: board

  def reveal_tiles_0(board, [%Tile{state: :revealed} | tail]), do: reveal_tiles_0(board, tail)
  def reveal_tiles_0(board, [%Tile{state: :marked} | tail]), do: reveal_tiles_0(board, tail)

  def reveal_tiles_0(%Board{grid: grid} = board, [%Tile{is_bomb?: true} = tile | _]),
    do: %{board | state: :loss, grid: Grid.set_tile(grid, Tile.reveal(tile))}

  def reveal_tiles_0(%Board{grid: grid} = board, [%Tile{bomb_count: 0} = tile | tail]) do
    block = Grid.get_block(grid, Tile.point(tile)) |> List.delete(tile)

    %{board | grid: Grid.set_tile(grid, Tile.reveal(tile))}
    |> reveal_tiles_0(Enum.uniq(tail ++ block))
  end

  defp game_state(grid, loss?)
  defp game_state(_, true), do: :loss

  defp game_state(grid, false) do
    if Grid.check_win(grid) do
      :win
    else
      :ok
    end
  end

  # endregion

  if Mix.env() == :dev do
    def change_tile_0(%Board{state: :new} = board, point) do
      %{board | grid: Grid.update_tile(board.grid, point, &Tile.reveal/1)}
    end

    def change_tile_1(%Board{state: :new, grid: grid} = board, point) do
      %{board | grid: Grid.update_tile(grid, point, &Tile.reveal/1)}
    end

    def bench() do
      board = Board.new_with_config(%{width: 100, height: 100, bomb_count: 0})

      Benchee.run(
        %{
          "0" => fn -> for x <- 0..99, y <- 0..99, do: Board.change_tile_0(board, {x, y}) end,
          "1" => fn -> for x <- 0..99, y <- 0..99, do: Board.change_tile_1(board, {x, y}) end
        },
        time: 10,
        memory_time: 2
      )
    end
  end
end
