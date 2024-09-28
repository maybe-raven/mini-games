defmodule Minesweeper.Board.Display do
  alias Minesweeper.Board
  defstruct [:tiles]

  def new(%Board{grid: grid, width: width, height: height}) do
    :array.to_list(grid)
    |> Enum.zip(0..(width - 1))
    |> Enum.flat_map(fn {column, x} ->
      :array.to_list(column)
      |> Enum.zip(0..(height - 1))
      |> Enum.map(fn {cell, y} -> {{x, y}, cell} end)
    end)
  end
end
