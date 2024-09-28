defmodule TetrisWeb.Game do
  use TetrisWeb, :live_view
  alias Tetris.Board
  alias Tetris.Block

  @tick_interval 500

  @spec new_game_button(Phoenix.LiveView.assigns()) :: Phoenix.LiveView.Rendered.t()
  def new_game_button(assigns) do
    ~H"""
    <button
      class="rounded-full px-4 py-2 w-fit h-fit mx-auto text-sm text-white bg-cyan-700 hover:bg-sky-800"
      phx-click="new_game"
    >
      New Game
    </button>
    """
  end

  @spec score_label(Phoenix.LiveView.assigns()) :: Phoenix.LiveView.Rendered.t()
  def score_label(%{board: nil} = assigns), do: ~H(<p class="text-white">0</p>)

  def score_label(%{board: %Board{completed_rows: []}} = assigns) do
    ~H"""
    <p class="transition duration-500 text-white"><%= Board.score(@board) %></p>
    """
  end

  def score_label(assigns) do
    ~H"""
    <p class="transition duration-100 text-green-500 scale-125"><%= Board.score(@board) %></p>
    """
  end

  def block_preview(%{board: nil} = assigns), do: ~H()
  def block_preview(%{board: %Board{next_block: nil}} = assigns), do: ~H()

  def block_preview(%{board: %Board{next_block: block}} = assigns) do
    height = Block.height(block)

    assigns =
      assign(assigns,
        height: height,
        width: Block.width(block),
        points: Block.points(block, {0, height - 1}),
        color: block.color
      )

    ~H"""
    <svg
      class="stroke-gray-400 stroke-[0.02] mx-auto"
      fill={@color}
      viewBox={"0 0 #{@width} #{@height}"}
      xmlns="http://www.w3.org/2000/svg"
    >
      <%= for {x, y} <- @points do %>
        <rect width="1" height="1" x={x} y={y} />
      <% end %>
    </svg>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :high_score, get_connect_params(socket)["high_score"]), layout: false}
  end

  # Event handlers
  def handle_event("player_control", %{"action" => "rotate"}, socket) do
    {:noreply, update_board(socket, Board.rotate(socket.assigns.board))}
  end

  def handle_event("player_control", %{"action" => "left"}, socket) do
    {:noreply, update_board(socket, Board.left(socket.assigns.board))}
  end

  def handle_event("player_control", %{"action" => "right"}, socket) do
    {:noreply, update_board(socket, Board.right(socket.assigns.board))}
  end

  def handle_event("player_control", %{"action" => "down"}, socket) do
    {:noreply, update_board(socket, Board.down(socket.assigns.board))}
  end

  def handle_event("player_input", %{"key" => "ArrowUp"}, %{assigns: %{paused: false}} = socket) do
    {:noreply, update_board(socket, Board.rotate(socket.assigns.board))}
  end

  def handle_event("player_input", %{"key" => "ArrowLeft"}, %{assigns: %{paused: false}} = socket) do
    {:noreply, update_board(socket, Board.left(socket.assigns.board))}
  end

  def handle_event(
        "player_input",
        %{"key" => "ArrowRight"},
        %{assigns: %{paused: false}} = socket
      ) do
    {:noreply, update_board(socket, Board.right(socket.assigns.board))}
  end

  def handle_event("player_input", %{"key" => "ArrowDown"}, %{assigns: %{paused: false}} = socket) do
    {:noreply, update_board(socket, Board.down(socket.assigns.board))}
  end

  def handle_event("player_input", %{"key" => "Escape"}, socket) do
    {:noreply, toggle_pause(socket)}
  end

  def handle_event("player_input", _, socket) do
    {:noreply, socket}
  end

  def handle_event("new_game", _, socket) do
    {:noreply, new_game(socket)}
  end

  def handle_info(:tick, socket) do
    {:noreply, tick(socket)}
  end

  @spec new_game(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  defp new_game(socket) do
    socket
    |> start_tick()
    |> update_board(%Board{})
    |> assign(:paused, false)
  end

  @spec tick(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  defp tick(%{assigns: %{game_over: true}} = socket) do
    socket |> stop_tick() |> update_high_score()
  end

  defp tick(%{assigns: %{board: board}} = socket) do
    updated_board =
      board
      |> Board.remove_completion()
      |> Board.find_completion()
      |> Board.push_next_block()
      |> Board.down()

    update_board(socket, updated_board)
  end

  defp start_tick(%{assigns: assigns} = socket) do
    case assigns[:tref] do
      nil ->
        {:ok, tref} = :timer.send_interval(@tick_interval, :tick)
        assign(socket, :tref, tref)

      _tref ->
        socket
    end
  end

  defp stop_tick(%{assigns: assigns} = socket) do
    case assigns[:tref] do
      nil ->
        socket

      tref ->
        {:ok, _} = :timer.cancel(tref)
        assign(socket, :tref, nil)
    end
  end

  defp toggle_pause(%{assigns: %{paused: true}} = socket) do
    socket |> start_tick() |> assign(:paused, false)
  end

  defp toggle_pause(%{assigns: %{paused: false}} = socket) do
    socket |> stop_tick() |> assign(:paused, true)
  end

  defp update_high_score(%{assigns: %{board: board} = assigns} = socket) do
    high_score =
      case assigns[:high_score] do
        nil -> Board.score(board)
        high_score -> max(Board.score(board), high_score)
      end

    socket
    |> assign(:high_score, high_score)
    |> push_event("high-score-update", %{high_score: high_score})
  end

  @spec update_board(Phoenix.LiveView.Socket.t(), Tetris.Board.t()) :: Phoenix.LiveView.Socket.t()
  defp update_board(socket, board) do
    assign(socket,
      board: board,
      fills: Board.all_fills(board),
      game_over: Board.overflow?(board)
    )
  end
end
