// Fetch map layer images ahead of time so the year slider and play button
// never wait on the network. Keeping the Image objects keeps them cached.
Shiny.addCustomMessageHandler("preload", function(urls) {
  window.preloadedLayers = urls.map(function(url) {
    var img = new Image();
    img.src = url;
    return img;
  });
});

// Show the images for a year (the data layer, and the ice layer if there is
// one) without a blank frame. They load hidden over the current ones, then
// all fade in at once, so land (in the data layer), ice and the bed stress
// arrows change together. The fade is a CSS transition on .paleo-layer
// (style.css); FADE_MS matches it.
var FADE_MS = 450;
var swapSeq = 0;  // newest year asked for
var shownSeq = 0; // newest year on screen
var rasters = []; // {id, seq} of every image on the map, oldest first
Shiny.addCustomMessageHandler("swap-layers", function(msg) {
  var map = HTMLWidgets.find("#map").getMap();
  var seq = ++swapSeq;
  var added = msg.layers.map(function(l, i) {
    var id = "raster-" + seq + "-" + i;
    var options = Object.assign({}, l.options, { opacity: 0, className: "paleo-layer" });
    // the same method leaflet::addRasterImage() uses, pointed at a file
    LeafletWidget.methods.addRasterImage.call(map, l.url, l.bounds, id, null, options);
    rasters.push({ id: id, seq: seq });
    return { layer: map.layerManager.getLayer("image", id), opacity: l.options.opacity };
  });
  // ponytail: Leaflet fires no load when none of a layer's tiles are in view,
  // and a slow file shouldn't hold the year back for long
  var timeout = new Promise(function(resolve) { setTimeout(resolve, 2000, null); });
  var loaded = added.map(function(a) {
    return Promise.race([new Promise(function(resolve) { a.layer.once("load", resolve); }), timeout]);
  });
  // a failed arrows file shows no arrows rather than another year's
  var arrows = msg.arrows && arrowsFor(msg.arrows).catch(function() { return null; });
  loaded.push(arrows && Promise.race([arrows, timeout]));
  Promise.all(loaded).then(function(done) {
    // A later year is already on screen: drop these unseen. A later year that
    // is only asked for doesn't stop this one, so slow loads during playback
    // still step through the years rather than freeze.
    if (seq < shownSeq) return;
    shownSeq = seq;
    added.forEach(function(a) { a.layer.setOpacity(a.opacity); });
    var showArrows = function(files) {
      if (!files || shownSeq !== seq) return;
      arrowLayer.setData(files[0], files[1]);
      arrowLayer.addTo(map);
    };
    arrowLayer.remove();
    showArrows(done[done.length - 1]);
    // arrows that missed the fade go on when they arrive, if still this year
    if (arrows && !done[done.length - 1]) arrows.then(showArrows);
    // older layers go once the fade is done. The old data layer stays opaque
    // beneath it, so the base map never shows through; ice above it fades out.
    rasters.forEach(function(r) {
      var layer = r.seq < seq && map.layerManager.getLayer("image", r.id);
      if (layer && layer.options.zIndex > 1) layer.setOpacity(0);
    });
    setTimeout(function() {
      rasters = rasters.filter(function(r) {
        if (r.seq >= seq) return true;
        map.layerManager.removeLayer("image", r.id);
        return false;
      });
    }, FADE_MS);
  });
});

// Bed stress arrows, drawn on one canvas from a pre-built file per year
// (data_pre_processing/build_backend.R). Each arrow is four int16 values:
// grid column, grid row, u * 100, v * 100.
var ArrowLayer = L.Layer.extend({
  onAdd: function(map) {
    this._canvas = L.DomUtil.create("canvas", "leaflet-zoom-hide", map.getPanes().overlayPane);
    this._canvas.style.pointerEvents = "none"; // map clicks pass through
    map.on("move zoomend", this.draw, this);
    this.draw();
  },
  onRemove: function(map) {
    this._canvas.remove();
    map.off("move zoomend", this.draw, this);
  },
  setData: function(axes, arrows) {
    this._axes = axes;
    this._arrows = arrows;
    if (this._map) this.draw();
  },
  draw: function() {
    var map = this._map, size = map.getSize(), ratio = window.devicePixelRatio || 1;
    var canvas = this._canvas, ctx = canvas.getContext("2d");
    canvas.width = size.x * ratio;
    canvas.height = size.y * ratio;
    canvas.style.width = size.x + "px";
    canvas.style.height = size.y + "px";
    L.DomUtil.setPosition(canvas, map.containerPointToLayerPoint([0, 0]));
    if (!this._arrows) return;

    // screen position of every grid column and row (the projection is separable)
    var xs = this._axes.xs, ys = this._axes.ys, i;
    var px = xs.map(function(x) { return map.latLngToContainerPoint([ys[0], x]).x; });
    var py = ys.map(function(y) { return map.latLngToContainerPoint([y, xs[0]]).y; });

    // keep arrows about 12px apart whatever the zoom, by skipping grid cells.
    // Cell width is averaged over the axis because positions are whole pixels.
    var cell = (px[px.length - 1] - px[0]) / (px.length - 1);
    var base = this._axes.stride;
    var stride = Math.max(base, base * Math.round(12 / cell / base));
    var maxLength = Math.min(stride * cell, 26) * 0.9;

    ctx.scale(ratio, ratio);
    ctx.strokeStyle = "white";
    ctx.lineWidth = 1.5;
    ctx.lineCap = "round";
    ctx.lineJoin = "round";
    ctx.beginPath();
    var d = this._arrows;
    for (i = 0; i < d.length; i += 4) {
      if (d[i] % stride || d[i + 1] % stride) continue;
      var x = px[d[i]], y = py[d[i + 1]];
      if (x < -30 || y < -30 || x > size.x + 30 || y > size.y + 30) continue;
      var u = d[i + 2] / 100, v = d[i + 3] / 100, magnitude = Math.sqrt(u * u + v * v);
      if (!magnitude) continue;
      // Drawn in screen pixels so the direction is true on the map. Arrows
      // point along (-u, -v), east and north, as the app always has. Length
      // grows with magnitude up to 2 N/m2, then stays capped.
      var length = maxLength * Math.min(1, Math.max(0.4, magnitude / 2));
      var dx = -u / magnitude, dy = v / magnitude;
      var tipX = x + dx * length / 2, tipY = y + dy * length / 2;
      var head = Math.max(3, length * 0.35);
      ctx.moveTo(x - dx * length / 2, y - dy * length / 2);
      ctx.lineTo(tipX, tipY);
      ctx.moveTo(tipX - head * (dx * 0.8 - dy * 0.6), tipY - head * (dy * 0.8 + dx * 0.6));
      ctx.lineTo(tipX, tipY);
      ctx.lineTo(tipX - head * (dx * 0.8 + dy * 0.6), tipY - head * (dy * 0.8 - dx * 0.6));
    }
    ctx.stroke();
  }
});

var arrowLayer = new ArrowLayer();
var arrowFiles = {}; // url -> promise of its contents
function arrowFile(url, parse) {
  return arrowFiles[url] = arrowFiles[url] || fetch(url).then(function(r) {
    if (!r.ok) throw new Error(url + ": " + r.status);
    return parse(r);
  }).catch(function(error) {
    delete arrowFiles[url]; // so the next request for it tries again
    throw error;
  });
}
function arrowData(url) {
  return arrowFile(url, function(r) { return r.arrayBuffer().then(function(b) { return new Int16Array(b); }); });
}

// [axes, arrows] for one year (arrows.url), fetching the other years
// (arrows.preload) in the background
function arrowsFor(arrows) {
  // this year's file first, so it isn't queued behind the others
  var files = Promise.all([
    arrowFile(arrows.axes, function(r) { return r.json(); }),
    arrowData(arrows.url)
  ]);
  arrows.preload.forEach(function(url) { arrowData(url).catch(function() {}); });
  return files;
}

// Move to a region and keep the map on it: panning stops 10 degrees past the
// region's layers and zooming out stops two levels below its starting view.
// Zoomed out far enough that the view is wider than those bounds, Leaflet
// centres the map on them and it can't be panned.
function showRegion(msg, tries) {
  var widget = HTMLWidgets.find("#map");
  var map = widget && widget.getMap();
  // the widget isn't up yet: try again shortly rather than drop the move
  if (!map) {
    if (tries < 50) setTimeout(showRegion, 100, msg, tries + 1);
    return;
  }
  map.setMaxBounds(null); // lift the old region's limits before moving
  map.setMinZoom(Math.floor(msg.view.zoom) - 2);
  map.setView([msg.view.lat, msg.view.lng], msg.view.zoom, { animate: false });
  map.setMaxBounds(msg.bounds);
}
Shiny.addCustomMessageHandler("region-view", function(msg) { showRegion(msg, 0); });

// Year marker on the time series graphs: move it without redrawing them. The
// graphs may not be up (no click yet), in which case there is nothing to move.
Shiny.addCustomMessageHandler("ts-year", function(msg) {
  var el = document.querySelector("#" + msg.id + " .js-plotly-plot");
  if (el) Plotly.relayout(el, { shapes: msg.shapes, annotations: msg.annotations });
});
