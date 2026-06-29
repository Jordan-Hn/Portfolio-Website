/* ============================================================
   Jordan Howson · Portfolio
   Vanilla JS, no dependencies.
   ============================================================ */
(function () {
  "use strict";

  /* Assemble the contact email at runtime so the plaintext address is never
     in the page source. Real browsers (and the headless PDF build) run this;
     most scrapers read the raw HTML and never see a "user@domain" string. */
  var email = document.querySelector(".email[data-user]");
  if (email) {
    var addr = email.getAttribute("data-user") + "@" + email.getAttribute("data-domain");
    email.setAttribute("href", "mailto:" + addr);
    email.textContent = addr;
  }

  /* Reveal the fixed nav on a slight scroll or near the top edge. */
  var nav = document.querySelector(".nav");
  if (!nav) { return; }

  var nearTop = false;
  var menuOpen = false;
  function update() {
    nav.classList.toggle("is-shown", window.scrollY > 32 || nearTop || menuOpen);
  }

  /* Mobile menu toggle. */
  var toggle = document.querySelector(".nav-toggle");
  var menu = document.getElementById("nav-menu");
  function setMenu(open) {
    menuOpen = open;
    if (menu) { menu.classList.toggle("is-open", open); }
    if (toggle) { toggle.setAttribute("aria-expanded", open ? "true" : "false"); }
    update();
  }
  if (toggle && menu) {
    toggle.addEventListener("click", function () { setMenu(!menuOpen); });
    menu.addEventListener("click", function (e) { if (e.target.closest("a")) { setMenu(false); } });
    document.addEventListener("click", function (e) { if (menuOpen && !nav.contains(e.target)) { setMenu(false); } });
    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape" && menuOpen) { setMenu(false); toggle.focus(); }
    });
  }

  window.addEventListener("scroll", update, { passive: true });
  window.addEventListener("mousemove", function (e) { nearTop = e.clientY <= 64; update(); });
  document.addEventListener("mouseleave", function () { nearTop = false; update(); });
  update();
})();
