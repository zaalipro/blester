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
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Category Filter Hook
const CategoryFilter = {
  mounted() {
    this.el.addEventListener('change', (e) => {
      this.pushEvent('filter-category', { category: e.target.value })
    })
  }
}

// Cart count update handler
const handleCartCountUpdate = (count) => {
  const cartCountElement = document.getElementById('cart-count')
  if (cartCountElement) {
    cartCountElement.textContent = count
    // Add a brief animation
    cartCountElement.classList.add('animate-pulse')
    setTimeout(() => {
      cartCountElement.classList.remove('animate-pulse')
    }, 1000)
  }
}

// Auto-dismiss flash messages
const autoDismissFlashMessages = () => {
  const flashMessages = document.querySelectorAll('[data-flash]')
  flashMessages.forEach(message => {
    setTimeout(() => {
      message.style.transition = 'opacity 0.5s ease-out'
      message.style.opacity = '0'
      setTimeout(() => {
        message.remove()
      }, 500)
    }, 3000)
  })
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {
    CategoryFilter
  }
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// Listen for cart count updates
liveSocket.connect()
liveSocket.onMessage((event) => {
  if (event.event === "update-cart-count") {
    handleCartCountUpdate(event.payload.count)
  }
})

// Auto-dismiss flash messages on page load
document.addEventListener('DOMContentLoaded', autoDismissFlashMessages)

