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
