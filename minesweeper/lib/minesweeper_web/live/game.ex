defmodule MinesweeperWeb.Game do
  use MinesweeperWeb, :live_view
  alias Minesweeper.Board
  alias Minesweeper.Board.Tile

  @default_difficulty :hard

  def mount(_params, _session, socket) do
    if connected?(socket) do
      {:ok, new_game(socket), layout: false}
    else
      {:ok, assign(socket, :board, nil), layout: false}
    end
  end

  attr :width, :integer, required: true

  def border_line(assigns) do
    ~H"""
    <%= for _ <- 1..@width do %>
      <div class="bordertb" />
    <% end %>
    """
  end

  def tile_class(tile, game_over?)

  def tile_class(%Tile{state: state, is_bomb?: is_bomb?, bomb_count: bomb_count}, true) do
    cond do
      state == :marked -> "bombflagged"
      is_bomb? and state == :revealed -> "bombdeath"
      is_bomb? -> "bombrevealed"
      state == :revealed -> "open#{bomb_count}"
      true -> "blank"
    end
  end

  def tile_class(%Tile{state: state, bomb_count: bomb_count}, false) do
    case state do
      :marked -> "bombflagged"
      :normal -> "blank"
      :highlighted -> "open0"
      :revealed -> "open#{bomb_count}"
    end
  end

  def face_class(%Board{state: :loss}), do: "facedead"
  def face_class(%Board{state: :win}), do: "facewin"
  def face_class(%Board{highlighted_points: []}), do: "facesmile"
  def face_class(_), do: "faceooh"

  def counter_class(counter, order_of_magnetude \\ 0)
  def counter_class(counter, 0), do: "time#{rem(counter, 10)}"

  def counter_class(counter, order_of_magnetude),
    do: "time#{(counter / order_of_magnetude) |> trunc |> rem(10)}"

  def handle_event("new_game", _, socket) do
    {:noreply, new_game(socket)}
  end

  def handle_event("remove_highlight", _, socket) do
    board = Board.remove_highlights(socket.assigns.board)
    {:noreply, assign(socket, :board, board)}
  end

  def handle_event(event, params, socket) do
    {:noreply, handle_input_event(event, params, socket)}
  end

  defp handle_input_event(_event, _, %{assigns: %{board: %Board{state: state}}} = socket)
       when state in [:loss, :win],
       do: socket

  defp handle_input_event(event, %{"x" => str_x, "y" => str_y}, socket) do
    x = String.to_integer(str_x)
    y = String.to_integer(str_y)
    board = get_function_for_event(event).(socket.assigns.board, {x, y})
    update_board(socket, board)
  end

  def handle_info(:update_timer, socket), do: {:noreply, update_timer(socket)}

  defp update_timer(%{assigns: %{start_time: nil, board: %Board{state: :ok}}} = socket),
    do: assign(socket, :start_time, Time.utc_now()) |> dbg()

  defp update_timer(%{assigns: %{start_time: start_time, board: %Board{state: :ok}}} = socket),
    do: assign(socket, :elapsed_time, Time.diff(Time.utc_now(), start_time)) |> dbg()

  defp update_timer(socket), do: socket

  defp new_game(socket) do
    tref =
      case socket.assigns[:tref] do
        nil -> :timer.send_interval(1000, :update_timer)
        tref -> tref
      end

    board = Board.new_with_config(%{width: 30, height: 16, bomb_count: 50})
    width = 24 * board.width + 30
    height = 24 * board.height + 93
    margin = (width - 207) / 2

    assign(socket,
      div_width: width,
      div_height: height,
      face_margin: margin,
      start_time: nil,
      elapsed_time: 0,
      tref: tref
    )
    |> update_board(board)
  end

  defp update_board(socket, board) do
    start_time =
      case socket.assigns.start_time do
        nil -> Time.utc_now()
        start_time -> start_time
      end

    bomb_counter = max(0, board.bomb_count - board.mark_count)
    assign(socket, board: board, bomb_counter: bomb_counter, start_time: start_time)
  end

  defp get_function_for_event(event)
  defp get_function_for_event("highlight_tile"), do: &Board.highlight_tile/2
  defp get_function_for_event("highlight_block"), do: &Board.highlight_block/2
  defp get_function_for_event("toggle_mark_tile"), do: &Board.toggle_mark_tile/2
  defp get_function_for_event("reveal_tile"), do: &Board.reveal_tile/2
  defp get_function_for_event("reveal_block"), do: &Board.reveal_block/2
end
