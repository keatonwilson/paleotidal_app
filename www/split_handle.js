// Draggable divider between the two panes in .split-container.
// The split is stored as CSS variables (flex-grow ratios), so it keeps its
// proportions when the window is resized. Each pane keeps at least MIN_PX.
(function () {
  var MIN_PX = 300;
  var STEP = 0.02; // keyboard step, as a fraction of the container width

  document.addEventListener("DOMContentLoaded", function () {
    var container = document.querySelector(".split-container");
    var handle = container && container.querySelector(".split-handle");
    if (!handle) return;

    var ratio = 7 / 12; // starting split: 7 : 5
    var frame = null;

    // Leaflet and plotly only redraw on a window resize event
    function notifyResize() {
      if (frame) return;
      frame = requestAnimationFrame(function () {
        frame = null;
        window.dispatchEvent(new Event("resize"));
      });
    }

    function usableWidth() {
      return container.clientWidth - handle.offsetWidth;
    }

    function setRatio(r) {
      var width = usableWidth();
      // too narrow for two minimum-width panes: leave the layout alone
      if (width < 2 * MIN_PX) return;
      var min = MIN_PX / width;
      ratio = Math.min(Math.max(r, min), 1 - min);
      container.style.setProperty("--split-left", ratio * 100);
      container.style.setProperty("--split-right", (1 - ratio) * 100);
      handle.setAttribute("aria-valuenow", Math.round(ratio * 100));
      notifyResize();
    }

    handle.addEventListener("pointerdown", function (e) {
      handle.setPointerCapture(e.pointerId);
      document.body.classList.add("split-dragging");
      e.preventDefault();
    });

    handle.addEventListener("pointermove", function (e) {
      if (!handle.hasPointerCapture(e.pointerId)) return;
      var left = container.getBoundingClientRect().left;
      var leftPx = e.clientX - left - handle.offsetWidth / 2;
      setRatio(leftPx / usableWidth());
    });

    function endDrag(e) {
      if (handle.hasPointerCapture(e.pointerId)) {
        handle.releasePointerCapture(e.pointerId);
      }
      document.body.classList.remove("split-dragging");
      notifyResize();
    }
    handle.addEventListener("pointerup", endDrag);
    handle.addEventListener("pointercancel", endDrag);

    // keyboard: arrow keys move the divider
    handle.addEventListener("keydown", function (e) {
      if (e.key === "ArrowLeft") {
        setRatio(ratio - STEP);
        e.preventDefault();
      } else if (e.key === "ArrowRight") {
        setRatio(ratio + STEP);
        e.preventDefault();
      }
    });

    // after a window resize, re-apply the clamp so minimums still hold
    window.addEventListener("resize", function () {
      setRatio(ratio);
    });
  });
})();
