defmodule Minesweeper.Board.Grid do
  alias Minesweeper.Board.Tile

  @type width :: pos_integer()
  @type height :: pos_integer()
  @type x :: non_neg_integer()
  @type y :: non_neg_integer()
  @type point :: {x(), y()}
  @type array_2d(elem_type) :: :erlang.array(:erlang.array(elem_type))
  @type t :: array_2d(Tile.t())

  @spec new(width(), height(), pos_integer()) :: t()
  def new(width, height, bomb_count) do
    grid = :array.new(height, default: :array.new(width, default: 0))

    grid =
      all_points(width, height)
      |> Enum.take_random(bomb_count)
      |> Enum.reduce(grid, fn point, acc ->
        update_tiles(acc, get_adjacent_points(width, height, point), fn tile_bomb_count ->
          if tile_bomb_count do
            tile_bomb_count + 1
          else
            nil
          end
        end)
        |> set_tile(point, nil)
      end)

    :array.map(
      fn y, row ->
        :array.map(
          fn x, value ->
            if value do
              Tile.new({x, y}, bomb_count: value, is_bomb?: false)
            else
              Tile.new({x, y}, is_bomb?: true)
            end
          end,
          row
        )
      end,
      grid
    )
  end

  @spec get_tile(array_2d(elem_type), point()) :: array_2d(elem_type) when elem_type: var
  def get_tile(grid, point)
  def get_tile(grid, {x, y}), do: :array.get(x, :array.get(y, grid))

  @spec get_tiles([point()], array_2d(elem_type)) :: [elem_type] when elem_type: var
  def get_tiles(points, grid), do: Enum.map(points, &get_tile(grid, &1))

  @spec set_tile(array_2d(elem_type), point(), elem_type) :: array_2d(elem_type)
        when elem_type: var
  def set_tile(grid, {x, y}, value),
    do: :array.set(y, :array.set(x, value, :array.get(y, grid)), grid)

  @spec set_tile(t(), Tile.t()) :: t()
  def set_tile(grid, %Tile{x: x, y: y} = tile), do: set_tile(grid, {x, y}, tile)

  @spec set_tiles([Tile.t()], t()) :: t()
  def set_tiles(tiles, grid)
  def set_tiles([], grid), do: grid
  def set_tiles([tile], grid), do: set_tile(grid, tile)

  def set_tiles(tiles, grid),
    do: Enum.reduce(tiles, grid, fn tile, acc -> set_tile(acc, tile) end)

  @spec update_tile(array_2d(elem_type), point(), (elem_type -> elem_type)) ::
          array_2d(elem_type)
        when elem_type: var
  def update_tile(grid, {x, y}, update_fun) do
    row = :array.get(y, grid)
    tile = :array.get(x, row)
    new_tile = update_fun.(tile)
    new_row = :array.set(x, new_tile, row)
    :array.set(y, new_row, grid)
  end

  @spec update_tiles(array_2d(elem_type), [point()], (elem_type -> elem_type)) ::
          array_2d(elem_type)
        when elem_type: var
  def update_tiles(grid, points, update_fun)
  def update_tiles(grid, [], _), do: grid
  def update_tiles(grid, [point], update_fun), do: update_tile(grid, point, update_fun)

  def update_tiles(grid, points, update_fun),
    do: Enum.reduce(points, grid, fn point, acc -> update_tile(acc, point, update_fun) end)

  @spec width(t()) :: width()
  def width(grid), do: :array.get(0, grid) |> :array.size()
  @spec height(t()) :: height()
  def height(grid), do: :array.size(grid)

  @spec get_adjacent_points(array_2d(any()), point()) :: [point()]
  def get_adjacent_points(grid, point), do: get_adjacent_points(width(grid), height(grid), point)

  @spec get_adjacent_points(width(), height(), point()) :: [point()]
  def get_adjacent_points(width, height, point)

  def get_adjacent_points(width, height, {target_x, target_y}) do
    for x <- max(0, target_x - 1)..min(width - 1, target_x + 1),
        y <- max(0, target_y - 1)..min(height - 1, target_y + 1),
        do: {x, y}
  end

  @spec get_block(t(), point()) :: [Tile.t()]
  def get_block(grid, point), do: get_adjacent_points(grid, point) |> get_tiles(grid)

  @spec reveal_tiles(t(), [Tile.t()]) :: {boolean(), t()}
  def reveal_tiles(grid, tiles)
  def reveal_tiles(grid, []), do: {false, grid}

  def reveal_tiles(grid, [%Tile{state: :revealed} | tail]), do: reveal_tiles(grid, tail)
  def reveal_tiles(grid, [%Tile{state: :marked} | tail]), do: reveal_tiles(grid, tail)

  def reveal_tiles(grid, [%Tile{is_bomb?: true} = tile | _]),
    do: {true, set_tile(grid, Tile.reveal(tile))}

  def reveal_tiles(grid, [%Tile{bomb_count: 0} = tile | tail]) do
    block = get_block(grid, Tile.point(tile)) |> List.delete(tile)
    reveal_tiles(set_tile(grid, Tile.reveal(tile)), Enum.uniq(tail ++ block))
  end

  def reveal_tiles(grid, [tile | tail]), do: reveal_tiles(set_tile(grid, Tile.reveal(tile)), tail)

  @spec check_win(t()) :: boolean()
  def check_win(grid) do
    grid
    |> :array.to_list()
    |> Enum.all?(fn row -> row |> :array.to_list() |> Enum.all?(&Tile.complete?/1) end)
  end

  @spec all_points(width(), height()) :: [point()]
  defp all_points(width, height) do
    for(x <- 0..(width - 1), y <- 0..(height - 1), do: {x, y})
  end
end
