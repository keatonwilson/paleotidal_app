// Fetch map layer images ahead of time so the year slider and play button
// never wait on the network. Keeping the Image objects keeps them cached.
Shiny.addCustomMessageHandler("preload", function(urls) {
  window.preloadedLayers = urls.map(function(url) {
    var img = new Image();
    img.src = url;
    return img;
  });
});
