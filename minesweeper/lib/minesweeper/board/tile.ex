defmodule Minesweeper.Board.Tile do
  alias Minesweeper.Board
  alias Minesweeper.Board.Tile

  @type bomb_count :: 0..8
  @type t :: %Tile{
          is_bomb?: boolean(),
          state: :normal | :marked | :highlighted | :revealed,
          bomb_count: bomb_count(),
          x: Board.x(),
          y: Board.y()
        }
  @enforce_keys [:x, :y]
  defstruct [:x, :y, is_bomb?: false, state: :normal, bomb_count: 0]

  @type transformer :: (t() -> t())

  @spec new(Board.point(), bomb_count: bomb_count(), is_bomb?: boolean()) :: t()
  def new({x, y}, opts) do
    bomb_count = Keyword.get(opts, :bomb_count, 0)
    is_bomb? = Keyword.get(opts, :is_bomb?, false)
    %Tile{x: x, y: y, bomb_count: bomb_count, is_bomb?: is_bomb?}
  end

  @spec toggle_mark(t()) :: t()
  def toggle_mark(%Tile{state: :revealed} = tile), do: tile
  def toggle_mark(%Tile{state: :marked} = tile), do: %{tile | state: :normal}
  def toggle_mark(tile), do: %{tile | state: :marked}

  @spec highlight(t()) :: t()
  def highlight(%Tile{state: :normal} = tile), do: %{tile | state: :highlighted}
  def highlight(tile), do: tile

  @spec remove_highlight(t()) :: t()
  def remove_highlight(%Tile{state: :highlighted} = tile), do: %{tile | state: :normal}
  def remove_highlight(tile), do: tile

  @spec reveal(t()) :: t()
  def reveal(%Tile{state: :marked} = tile), do: tile
  def reveal(tile), do: %{tile | state: :revealed}

  def complete?(%Tile{state: state}), do: state == :revealed or state == :marked

  @spec point(t()) :: Board.point()
  def point(%Tile{x: x, y: y}), do: {x, y}
end
