# ponytail: geospatial base ships GDAL/GEOS/PROJ/udunits for sf/terra in renv.lock
FROM rocker/geospatial:4.6.1
# cache outside /root: the library symlinks into it and the app runs as rstudio
ENV RENV_CONFIG_REPOS_OVERRIDE=https://packagemanager.posit.co/cran/__linux__/noble/latest \
    RENV_PATHS_LIBRARY=/renv/library \
    RENV_PATHS_CACHE=/renv/cache
RUN git clone --depth 1 https://github.com/keatonwilson/paleotidal_app /app
WORKDIR /app
# .Rprofile sources renv/activate.R, which sets renv up itself
RUN R -e 'renv::restore()'
# HF runs containers as uid 1000; rocker already has that user (rstudio)
USER rstudio
CMD ["R", "-e", "shiny::runApp('/app', host = '0.0.0.0', port = 3838)"]
