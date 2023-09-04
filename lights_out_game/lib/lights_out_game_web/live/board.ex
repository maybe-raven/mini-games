defmodule LightsOutGameWeb.Board do
  use LightsOutGameWeb, :live_view

  defmacrop const_max_x, do: 4
  defmacrop const_max_y, do: 4
  defmacrop const_default_difficulty, do: 2
  defmacrop transition_delay_unit, do: 60

  attr :win_point, :any, default: nil
  attr :x, :integer, required: true
  attr :y, :integer, required: true
  attr :value, :boolean, required: true

  def cell(assigns) do
    if assigns.win_point do
      {win_y, win_x} = assigns.win_point
      distance = Kernel.abs(win_x - assigns.x) + Kernel.abs(win_y - assigns.y)
      delay = distance * transition_delay_unit()

      assigns = assign(assigns, :style, "transition-delay: #{delay}ms;")

      ~H"""
      <button
        disabled
        class="aspect-square transition ease-in-out duration-300 bg-transparent"
        style={@style}
      />
      """
    else
      classes =
        if assigns.value do
          ["aspect-square", "bg-indigo-400", "hover:bg-indigo-300"]
        else
          ["aspect-square", "bg-stone-400", "hover:bg-stone-300"]
        end

      assigns = assign(assigns, :classes, classes)

      ~H"""
      <button class={@classes} phx-click="toggle" phx-value-x={@x} phx-value-y={@y} />
      """
    end
  end

  attr :win_point, :any, default: nil
  attr :steps, :integer, required: true

  def win_overlay(assigns) do
    classes = ["absolute flex flex-col justify-center items-center w-full h-full space-y-2"]

    classes =
      if assigns.win_point do
        classes ++ ["text-white", "transition duration-200 delay-500"]
      else
        classes ++ ["text-transparent", "z-[-1]"]
      end

    assigns = assign(assigns, :classes, classes)

    ~H"""
    <div class={@classes}>
      <div class="text-5xl">You won!</div>
      <p>You solved the puzzle in <%= assigns.steps %> steps.</p>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    socket = initialize(socket, const_default_difficulty())
    {:ok, socket}
  end

  def handle_event("toggle", %{"x" => str_x, "y" => str_y}, socket) do
    grid = socket.assigns.grid
    x = String.to_integer(str_x)
    y = String.to_integer(str_y)

    updated_grid = toggle_tile(grid, {y, x})
    win_point = if(detect_win?(updated_grid), do: {y, x}, else: nil)

    socket =
      socket
      |> assign(grid: updated_grid)
      |> assign(win_point: win_point)
      |> assign(:steps, socket.assigns.steps + 1)

    {:noreply, socket}
  end

  def handle_event("difficulty_changed", %{"difficulty" => str_difficulty}, socket) do
    difficulty = String.to_integer(str_difficulty)
    {:noreply, assign(socket, :difficulty, difficulty)}
  end

  def handle_event("restart", %{"difficulty" => str_difficulty}, socket) do
    difficulty = String.to_integer(str_difficulty)
    {:noreply, initialize(socket, difficulty)}
  end

  defp initialize(socket, difficulty) do
    socket
    |> assign(grid: initialize_grid(difficulty))
    |> assign(win_point: nil)
    |> assign(difficulty: difficulty)
    |> assign(:steps, 0)
  end

  defp initialize_grid(difficulty) do
    initial_grid =
      for x <- 0..const_max_x(), y <- 0..const_max_y(), into: %{}, do: {{y, x}, false}

    initial_grid
    |> Map.keys()
    |> Enum.take_random(difficulty)
    |> Enum.reduce(initial_grid, fn point, grid -> toggle_tile(grid, point) end)
  end

  defp detect_win?(grid) do
    Enum.all?(grid, fn {_, value} -> !value end)
  end

  defp toggle_tile(grid, point) do
    find_adjacent_tiles(point)
    |> Enum.reduce(grid, fn point, acc -> Map.put(acc, point, !grid[point]) end)
  end

  defp find_adjacent_tiles({y, x}) do
    prev_x = Kernel.max(0, x - 1)
    prev_y = Kernel.max(0, y - 1)
    next_x = Kernel.min(const_max_x(), x + 1)
    next_y = Kernel.min(const_max_y(), y + 1)

    MapSet.new([{y, x}, {prev_y, x}, {y, prev_x}, {next_y, x}, {y, next_x}])
  end
end
