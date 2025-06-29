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

liveSocket.connect()

// Auto-dismiss flash messages on page load
document.addEventListener('DOMContentLoaded', autoDismissFlashMessages)

// Handle category filter change
document.addEventListener('DOMContentLoaded', function() {
  const categorySelect = document.getElementById('category-filter');
  if (categorySelect) {
    categorySelect.addEventListener('change', function() {
      const selectedCategory = this.value;
      const currentUrl = new URL(window.location);
      
      if (selectedCategory) {
        currentUrl.searchParams.set('category', selectedCategory);
      } else {
        currentUrl.searchParams.delete('category');
      }
      
      // Remove page parameter when changing category
      currentUrl.searchParams.delete('page');
      
      window.location.href = currentUrl.toString();
    });
  }
});

// Auto-dismiss flash messages
document.addEventListener('DOMContentLoaded', function() {
  const flashMessages = document.querySelectorAll('.flash-message');
  flashMessages.forEach(function(message) {
    setTimeout(function() {
      message.style.opacity = '0';
      setTimeout(function() {
        message.remove();
      }, 300);
    }, 3000);
  });
});

