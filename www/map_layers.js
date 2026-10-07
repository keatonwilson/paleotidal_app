// Fetch map layer images ahead of time so the year slider and play button
// never wait on the network. Keeping the Image objects keeps them cached.
Shiny.addCustomMessageHandler("preload", function(urls) {
  window.preloadedLayers = urls.map(function(url) {
    var img = new Image();
    img.src = url;
    return img;
  });
});

// Show a new image in a raster slot ("data" or "ice") without a blank frame.
// The new layer is drawn over the current one, which is only removed once the
// new one has loaded and faded in.
var layerSeq = {};
Shiny.addCustomMessageHandler("swap-layer", function(msg) {
  var map = HTMLWidgets.find("#map").getMap();
  var seq = layerSeq[msg.slot] = (layerSeq[msg.slot] || 0) + 1;
  var id = msg.slot + "-" + seq;
  var previous = msg.slot + "-" + (seq - 1);
  // the same method leaflet::addRasterImage() uses, pointed at a file
  LeafletWidget.methods.addRasterImage.call(map, msg.url, msg.bounds, id, null, msg.options);
  map.layerManager.getLayer("image", id).once("load", function() {
    setTimeout(function() { map.layerManager.removeLayer("image", previous); }, 250);
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

    // keep arrows about 12px apart whatever the zoom, by skipping grid cells
    var cell = px[1] - px[0];
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
var arrowsWanted = null;
function arrowFile(url, parse) {
  return arrowFiles[url] = arrowFiles[url] || fetch(url).then(parse);
}
function arrowData(url) {
  return arrowFile(url, function(r) { return r.arrayBuffer().then(function(b) { return new Int16Array(b); }); });
}

// msg.url is the year to show; no url clears the arrows
Shiny.addCustomMessageHandler("arrows", function(msg) {
  var map = HTMLWidgets.find("#map").getMap();
  arrowsWanted = msg.url || null;
  if (!msg.url) {
    arrowLayer.remove();
    return;
  }
  msg.preload.forEach(arrowData);
  Promise.all([
    arrowFile(msg.axes, function(r) { return r.json(); }),
    arrowData(msg.url)
  ]).then(function(files) {
    if (arrowsWanted !== msg.url) return; // a later year was asked for meanwhile
    arrowLayer.setData(files[0], files[1]);
    arrowLayer.addTo(map);
  });
});
