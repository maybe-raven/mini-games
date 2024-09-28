defmodule Tetris.Point do
  @type x :: non_neg_integer()
  @type y :: non_neg_integer()
  @type t :: {x(), y()}

  @type offset :: {integer(), integer()}

  @spec random_top(non_neg_integer()) :: Tetris.Point.t()
  def random_top(max_x), do: {Enum.random(0..max_x), 0}

  @spec left(Tetris.Point.t()) :: Tetris.Point.t()
  def left({x, y}), do: {x - 1, y}

  @spec right(Tetris.Point.t()) :: Tetris.Point.t()
  def right({x, y}), do: {x + 1, y}

  @spec down(Tetris.Point.t()) :: Tetris.Point.t()
  def down({x, y}), do: {x, y + 1}

  @spec up(Tetris.Point.t()) :: Tetris.Point.t()
  def up({x, y}), do: {x, y - 1}

  @spec translate(Tetris.Point.t(), offset()) :: Tetris.Point.t()
  def translate({origin_x, origin_y}, {offset_x, offset_y}),
    do: {origin_x + offset_x, origin_y + offset_y}
end
