// Sound toggle: remembers on/off across pages and resumes where the song left off.
(function () {
  var btn = document.getElementById("sound-toggle");
  if (!btn) return;

  var KEY = "petcare-sound";
  var TIME_KEY = "petcare-sound-time";
  var audio = new Audio(btn.getAttribute("data-src"));
  audio.loop = true;
  audio.volume = 0.5;

  function read(store, key) { try { return store.getItem(key); } catch (e) { return null; } }
  function write(store, key, val) { try { store.setItem(key, val); } catch (e) {} }

  var on = read(localStorage, KEY) === "on";
  var saved = parseFloat(read(sessionStorage, TIME_KEY));
  if (!isNaN(saved)) {
    audio.addEventListener("loadedmetadata", function () {
      if (saved < audio.duration) audio.currentTime = saved;
    }, { once: true });
  }

  function render() {
    btn.setAttribute("aria-pressed", on ? "true" : "false");
    btn.querySelector(".sound-label").textContent = on ? "Sound on" : "Sound off";
  }

  function play() {
    audio.play().catch(function () {
      // Browsers block sound until the visitor clicks something. Start on the first click.
      var resume = function () { if (on) audio.play().catch(function () {}); };
      document.addEventListener("pointerdown", resume, { once: true });
      document.addEventListener("keydown", resume, { once: true });
    });
  }

  btn.addEventListener("click", function () {
    on = !on;
    write(localStorage, KEY, on ? "on" : "off");
    if (on) play(); else audio.pause();
    render();
  });

  window.addEventListener("pagehide", function () {
    write(sessionStorage, TIME_KEY, String(audio.currentTime));
  });

  render();
  if (on) play();
})();
