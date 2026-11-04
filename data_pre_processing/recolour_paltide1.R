# One-off: bring the PALTIDE1 (nw_europe) layers in line with a land colour or
# label change. Its inputs are gone (see build_backend.R), so the PNGs are
# edited in place: pixels exactly the old land colour take the new one. Land is
# the only place that colour appears, since layer colours come from palettes
# plus na.color.
#
# Run from the project root: Rscript data_pre_processing/recolour_paltide1.R

source("R/mod_map.R") # land_col

old = c(190, 190, 190) # #bebebe
new = as.vector(grDevices::col2rgb(land_col))

for (file in list.files("www/layers/nw_europe", pattern = "\\.png$", full.names = TRUE)) {
  img = png::readPNG(file)
  rgb = round(img[, , 1:3] * 255)
  hit = rgb[, , 1] == old[1] & rgb[, , 2] == old[2] & rgb[, , 3] == old[3]
  if (!any(hit)) next
  for (k in 1:3) img[, , k][hit] = new[k] / 255
  png::writePNG(img, file)
  message(file, ": ", sum(hit), " pixels")
}

static_path = "data/app/nw_europe/static.rds"
static = readRDS(static_path)
static$label = "Northwest European Shelf" # must match nw_europe_p2, see build_backend.R
saveRDS(static, static_path)
