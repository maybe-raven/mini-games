defmodule Tetris.Block do
  alias Tetris.Block
  alias Tetris.Point

  @type shape :: :line | :square | :t | :l | :l_reverse | :z | :z_reverse
  @possible_shapes [:line, :square, :t, :l, :l_reverse, :z, :z_reverse]

  @type color :: String.t()
  @possible_colors [
    "red",
    "orange",
    "amber",
    "yellow",
    "lime",
    "green",
    "emerald",
    "teal",
    "cyan",
    "sky",
    "blue",
    "indigo",
    "violet",
    "purple",
    "fuchsia",
    "pink",
    "rose"
  ]

  @type(orientation :: :up, :right, :down, :left)

  @type size :: 1..4

  @type t :: %Block{shape: shape(), color: color(), orientation: orientation()}
  @enforce_keys [:shape, :color, :orientation]
  defstruct [:shape, :color, :orientation]

  @spec random() :: Tetris.Block.t()
  def random() do
    %Block{
      shape: Enum.random(@possible_shapes),
      color: Enum.random(@possible_colors),
      orientation: :up
    }
  end

  @spec rotate(Tetris.Block.t()) :: Tetris.Block.t()
  def rotate(%Block{shape: :square} = block), do: block

  def rotate(%Block{shape: shape, orientation: :up} = block)
      when shape in [:line, :z, :z_reverse],
      do: %{block | orientation: :right}

  def rotate(%Block{shape: shape, orientation: :right} = block)
      when shape in [:line, :z, :z_reverse],
      do: %{block | orientation: :up}

  def rotate(%Block{orientation: :up} = block), do: %{block | orientation: :right}
  def rotate(%Block{orientation: :right} = block), do: %{block | orientation: :down}
  def rotate(%Block{orientation: :down} = block), do: %{block | orientation: :left}
  def rotate(%Block{orientation: :left} = block), do: %{block | orientation: :up}

  @spec width(Tetris.Block.t()) :: size()
  def width(%Block{shape: :line, orientation: :up}), do: 1
  def width(%Block{shape: :line, orientation: :right}), do: 4
  def width(%Block{shape: :square}), do: 2
  def width(%Block{shape: :t, orientation: orientation}) when orientation in [:up, :down], do: 3

  def width(%Block{shape: :t, orientation: orientation}) when orientation in [:left, :right],
    do: 2

  def width(%Block{shape: shape, orientation: :up}) when shape in [:z, :z_reverse], do: 3
  def width(%Block{shape: shape, orientation: :right}) when shape in [:z, :z_reverse], do: 2

  def width(%Block{shape: shape, orientation: orientation})
      when shape in [:l, :l_reverse] and orientation in [:up, :down],
      do: 2

  def width(%Block{shape: shape, orientation: orientation})
      when shape in [:l, :l_reverse] and orientation in [:left, :right],
      do: 3

  @spec height(Tetris.Block.t()) :: size()
  def height(block), do: block |> rotate() |> width()

  @spec points(Tetris.Block.t(), Tetris.Point.offset() | nil) :: [Tetris.Point.t()]
  def points(block, offset \\ nil)
  def points(%Block{shape: :square}, nil), do: [{0, 0}, {0, -1}, {1, 0}, {1, -1}]

  def points(%Block{shape: :line, orientation: :up}, nil),
    do: [{0, 0}, {0, -1}, {0, -2}, {0, -3}]

  def points(%Block{shape: :line}, nil), do: [{0, 0}, {1, 0}, {2, 0}, {3, 0}]
  def points(%Block{shape: :t, orientation: :up}, nil), do: [{0, 0}, {1, 0}, {2, 0}, {1, -1}]

  def points(%Block{shape: :t, orientation: :down}, nil),
    do: [{0, -1}, {1, -1}, {2, -1}, {1, 0}]

  def points(%Block{shape: :t, orientation: :right}, nil),
    do: [{0, 0}, {0, -1}, {0, -2}, {1, -1}]

  def points(%Block{shape: :t, orientation: :left}, nil),
    do: [{1, 0}, {1, -1}, {1, -2}, {0, -1}]

  def points(%Block{shape: :l, orientation: :up}, nil), do: [{0, 0}, {0, -1}, {0, -2}, {1, 0}]

  def points(%Block{shape: :l, orientation: :right}, nil),
    do: [{0, -1}, {1, -1}, {2, -1}, {0, 0}]

  def points(%Block{shape: :l, orientation: :down}, nil),
    do: [{1, 0}, {1, -1}, {1, -2}, {0, -2}]

  def points(%Block{shape: :l, orientation: :left}, nil), do: [{0, 0}, {1, 0}, {2, 0}, {2, -1}]

  def points(%Block{shape: :l_reverse, orientation: :up}, nil),
    do: [{1, 0}, {1, -1}, {1, -2}, {0, 0}]

  def points(%Block{shape: :l_reverse, orientation: :right}, nil),
    do: [{0, 0}, {1, 0}, {2, 0}, {0, -1}]

  def points(%Block{shape: :l_reverse, orientation: :down}, nil),
    do: [{0, 0}, {0, -1}, {0, -2}, {1, -2}]

  def points(%Block{shape: :l_reverse, orientation: :left}, nil),
    do: [{0, -1}, {1, -1}, {2, -1}, {2, 0}]

  def points(%Block{shape: :z, orientation: :up}, nil), do: [{0, -1}, {1, -1}, {1, 0}, {2, 0}]

  def points(%Block{shape: :z, orientation: :right}, nil),
    do: [{0, 0}, {0, -1}, {1, -1}, {1, -2}]

  def points(%Block{shape: :z_reverse, orientation: :up}, nil),
    do: [{0, 0}, {1, -1}, {1, 0}, {2, -1}]

  def points(%Block{shape: :z_reverse, orientation: :right}, nil),
    do: [{1, 0}, {0, -1}, {1, -1}, {0, -2}]

  def points(block, offset), do: block |> points() |> Enum.map(&Point.translate(&1, offset))
end
