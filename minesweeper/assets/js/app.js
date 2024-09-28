// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

const left = 0
const middle = 1
const right = 2
let active_button = null;
let game_over = false;

window.addEventListener("mouseup", e => { active_button = null; })

let Hooks = {}
Hooks.GameStateManager = {
    updated() {
        game_over = this.el.getAttribute("game-over") == "true"
        console.log(game_over)
    }
}
Hooks.Face = {
    mounted() {
        this.faceClassName = null
        this.el.addEventListener("mousedown", (_) => {
            this.faceClassName = this.el.className
            this.el.className = "facepressed"
        })
        this.el.addEventListener("mouseup", (_) => {
            if (this.faceClassName == null) { return }
            this.el.className = this.faceClassName
            this.faceClassName = null
        })
        this.el.addEventListener("mouseleave", (_) => {
            if (this.faceClassName == null) { return }
            this.el.className = this.faceClassName
            this.faceClassName = null
        })
    }
}
Hooks.Board = {
    mounted() {
        this.pushEvent("", {})
        this.el.addEventListener("drag", e => { e.preventDefault() })
        this.el.addEventListener("dragstart", e => { e.preventDefault() })
        this.el.addEventListener("contextmenu", e => { e.preventDefault() })
        this.el.addEventListener("mouseleave", e => {
            if (game_over) { return }
            // Remove highlight on any tiles when cursor leaves the board.
            if (active_button == left || active_button == middle) {
                this.pushEvent("remove_highlight")
            }
        })
    }
}
Hooks.Tile = {
    mounted() {
        const coordinate = { x: this.el.getAttribute("x"), y: this.el.getAttribute("y") }

        this.el.addEventListener("mousedown", e => {
            if (game_over) { return }

            let button = e.button
            // Control + left click is functionally identical to right click.
            if (e.ctrlKey && e.button == left) { button = right }
            // Left + right click has the same functionality has middle click.
            if ((active_button == left && button == right) || (active_button == right && button == left)) {
                button = middle
            }
            // Register currently pressed button for different behaviors in other handlers.
            active_button = button

            // Push current input event to server.
            if (button == left) {
                this.pushEvent("highlight_tile", coordinate)
            } else if (button == middle) {
                this.pushEvent("highlight_block", coordinate)
            } else if (button == right) {
                this.pushEvent("toggle_mark_tile", coordinate)
            }
        })
        this.el.addEventListener("mouseenter", e => {
            if (game_over) { return }

            // Fire input event when cursor enters a tile while left or middle button is pressed.
            if (active_button == left) {
                this.pushEvent("highlight_tile", coordinate)
            } else if (active_button == middle) {
                this.pushEvent("highlight_block", coordinate)
            }
        })
        this.el.addEventListener("mouseup", e => {
            if (game_over) { return }

            // Remove the tile or block when left or middle click is released.
            if (active_button == left) {
                this.pushEvent("reveal_tile", coordinate)
            } else if (active_button == middle) {
                this.pushEvent("reveal_block", coordinate)
            }
            active_button = null;
        })
    }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken }, hooks: Hooks })

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

