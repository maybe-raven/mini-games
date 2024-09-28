defmodule Tetris.Board do
  alias Tetris.Point
  alias Tetris.Board
  alias Tetris.Block

  @type fills :: %{Point.t() => Block.color()} | %{}
  @type t :: %Board{
          width: pos_integer(),
          height: pos_integer(),
          current_block: Block.t() | nil,
          next_block: Block.t() | nil,
          position: Point.t() | nil,
          fills: fills(),
          has_new_fills?: boolean(),
          completed_rows: [non_neg_integer()],
          n_rows_completed: non_neg_integer()
        }
  defstruct width: 10,
            height: 15,
            current_block: nil,
            next_block: nil,
            position: nil,
            fills: %{},
            has_new_fills?: false,
            completed_rows: [],
            n_rows_completed: 0

  @score_multiplier 100

  @spec score(Tetris.Board.t()) :: non_neg_integer()
  def score(%Board{n_rows_completed: n_rows}), do: n_rows * @score_multiplier

  @spec push_next_block(Board.t()) :: Board.t()
  def push_next_block(%Board{next_block: nil} = board),
    do: push_next_block(%{board | next_block: Block.random()})

  def push_next_block(%Board{current_block: nil, completed_rows: [], next_block: block} = board) do
    position = Point.random_top(max_x_for_block(board, block))
    %{board | position: position, current_block: block, next_block: Block.random()}
  end

  def push_next_block(board), do: board

  @spec left(Tetris.Board.t()) :: Tetris.Board.t()
  def left(%Board{position: nil} = board), do: board
  def left(%Board{position: {0, _}} = board), do: board

  def left(board), do: shift(board, {-1, 0})

  @spec right(Tetris.Board.t()) :: Tetris.Board.t()
  def right(%Board{position: nil} = board), do: board

  def right(board), do: shift(board, {1, 0})

  @spec shift(Board.t(), Point.offset()) :: Board.t()
  defp shift(%Board{position: position} = board, offset) do
    if collision?(board, offset) do
      board
    else
      %{board | position: Point.translate(position, offset)}
    end
  end

  @spec rotate(Tetris.Board.t()) :: Tetris.Board.t()
  def rotate(%Board{current_block: nil} = board), do: board

  def rotate(%Board{current_block: block, position: {x, y}} = board) do
    rotated_block = Block.rotate(block)
    max_x = max_x_for_block(board, rotated_block)

    updated_board =
      if x > max_x do
        %{board | current_block: rotated_block, position: {max_x, y}}
      else
        %{board | current_block: rotated_block}
      end

    if collision?(updated_board) do
      board
    else
      updated_board
    end
  end

  @spec down(Tetris.Board.t()) :: Tetris.Board.t()
  def down(%Board{position: nil} = board), do: board

  def down(%Board{position: position} = board) do
    if collision?(board, {0, 1}) do
      fill_block(board)
    else
      %{board | position: Point.down(position)}
    end
  end

  @spec find_completion(Tetris.Board.t()) :: Tetris.Board.t()
  def find_completion(%Board{has_new_fills?: false} = board), do: board
  def find_completion(%Board{fills: fills} = board) when map_size(fills) == 0, do: board

  def find_completion(%Board{fills: fills, width: width, n_rows_completed: n_rows} = board) do
    filled_points = Map.keys(fills)
    min_filled_y = filled_points |> Enum.map(fn {_x, y} -> y end) |> Enum.min()

    completed_rows =
      min_filled_y..max_y(board)
      |> Enum.filter(fn y ->
        0..(width - 1)
        |> Enum.map(&{&1, y})
        |> Enum.all?(fn point -> point in filled_points end)
      end)

    %{
      board
      | completed_rows: completed_rows,
        has_new_fills?: false,
        n_rows_completed: n_rows + length(completed_rows)
    }
  end

  @spec remove_completion(Tetris.Board.t()) :: Tetris.Board.t()
  def remove_completion(%Board{completed_rows: []} = board), do: board

  def remove_completion(%Board{fills: fills, completed_rows: completed_rows} = board) do
    updated_fills =
      completed_rows
      |> Enum.reduce(fills, fn row, acc ->
        acc
        |> Enum.map(fn {{x, y} = point, color} ->
          cond do
            y > row -> {point, color}
            y < row -> {{x, y + 1}, color}
            y == row -> nil
          end
        end)
        |> Enum.filter(&Function.identity/1)
      end)
      |> Map.new()

    %{board | fills: updated_fills, completed_rows: []}
  end

  @spec all_fills(Tetris.Board.t()) :: fills()
  def all_fills(%Board{current_block: nil, fills: fills}), do: fills

  def all_fills(%Board{current_block: block, position: position, fills: fills}) do
    block
    |> Block.points(position)
    |> Enum.into(fills, fn point -> {point, block.color} end)
  end

  @spec overflow?(Tetris.Board.t()) :: boolean()
  def overflow?(%Board{has_new_fills?: false}), do: false

  def overflow?(%Board{fills: fills}) do
    Enum.any?(fills, fn {{_x, y}, _color} -> y < 0 end)
  end

  # Internal Helpers
  defp fill_block(%Board{position: position} = board) do
    if collision?(board) do
      fill_block(%{board | position: Point.up(position)})
    else
      %{board | current_block: nil, position: nil, has_new_fills?: true, fills: all_fills(board)}
    end
  end

  @spec collision?(Board.t(), Point.offset()) :: boolean()
  defp collision?(%Board{fills: fills} = board, offset \\ {0, 0}) do
    if bounding_collision?(board, offset) do
      true
    else
      collision_points = collision_points(board, offset)
      fills |> Map.keys() |> Enum.any?(fn point -> point in collision_points end)
    end
  end

  @spec bounding_collision?(Board.t(), Point.offset()) :: boolean()
  defp bounding_collision?(%Board{position: position} = board, offset) do
    {x, y} = Point.translate(position, offset)
    x < 0 or x > max_x_for_block(board) or y > max_y(board)
  end

  @spec collision_points(Board.t(), Point.offset()) :: [Point.t()]
  defp collision_points(%Board{current_block: block, position: position}, {0, 0}),
    do: Block.points(block, position)

  defp collision_points(%Board{current_block: block, position: position}, offset),
    do: Block.points(block, position) ++ Block.points(block, Point.translate(position, offset))

  @spec max_x_for_block(Board.t()) :: Point.x()
  defp max_x_for_block(%Board{current_block: block} = board), do: board.width - Block.width(block)
  @spec max_x_for_block(Board.t(), Block.t()) :: Point.x()
  defp max_x_for_block(board, block), do: board.width - Block.width(block)

  @spec max_y(Board.t()) :: Point.y()
  defp max_y(%Board{height: height}), do: height - 1
end
