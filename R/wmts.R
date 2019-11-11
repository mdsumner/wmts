#' OGC Webmap Tile Server (WMTS)
#'
#' Get raster from WMTS
#'
#' Beware that if 'zoom' is set the 'max_tiles' argument is ignored. Use
#' the function defaults to discover a reasonable zoom level, then re-run with a
#' higher (more pixels) or lower (fewer pixels) zoom level.
#' @param x WMTS address
#' @param loc something we can get an extent from
#' @param buffer radius in metres (in the case 'loc' is a single point, and is longlat)
#' @param silent suppress messages (default is `FALSE`)
#' @param ... ignored
#' @param zoom override hueristic for zoom level (take care! no safety checks)
#' @param max_tiles max number of tiles for zoom hueristic (default 25)
#' @param bands bands to get (default is 1,2,3 assuming RGB)
#' @export
#' @return raster brick
#' @examples
#' centre <- c(-80.888, 32.332)  ## lonlat
#' radius <- 4000                ## metres
#' u <- "WMTS:https://basemap.nationalmap.gov/arcgis/rest/services/USGSTopo/MapServer/WMTS/1.0.0/WMTSCapabilities.xml,layer=USGSTopo,tilematrixset=default028mm"
#' x <- wmts(u, centre, buffer = radius)
#' #f <- system.file("gpkg/nc.gpkg", package = "sf", mustWork = TRUE)
#' #sf <- sf::read_sf(f)
#' #x <- wmts(u, sf)
#'
#'
#' #tab <- tibble::as_tibble(raster::as.data.frame(x, xy = TRUE))
#' #names(tab) <- c("x", "y", "red", "green", "blue")
#' ##tab <- dplyr::filter(tab, !is.na(red))
#' #
#' ### ... when we have missing values, we should drop them or rgb() will error
#' #tab$hex <- rgb(tab$red, tab$green, tab$blue, maxColorValue = 255)
#' #library(ggplot2)
#' #ggplot(tab, aes(x, y, fill = hex)) +
#' #   geom_raster() +
#' #   coord_equal() +
#' #   scale_fill_identity()
wmts <- function(x, loc, buffer = NULL, silent = FALSE, ..., zoom = NULL, max_tiles = 25, bands = 1:3) {

  if (is.numeric(loc)) loc <- matrix(loc, byrow = TRUE, ncol = 2)
  bbox_pair <- spatial_bbox(loc, buffer)
  my_bbox <- bbox_pair$tile_bbox
  bb_points <- bbox_pair$user_points
  ## all we need is zoom
  tile_grid <- slippymath::bbox_to_tile_grid(my_bbox, max_tiles = max_tiles,
                                           zoom = zoom)
  zoom_level <- tile_grid$zoom
  if (!is.null(zoom)) {
    zoom_level <- zoom
    max_tiles <- NULL
  }
  if (!silent) {
    writeLines(sprintf("zoom: %s", zoom_level))
  }
  uzoom <- paste0(x, sprintf(",zoom_level=%i", zoom_level))
  br <- raster::subset(raster::brick(uzoom), bands)
  ex <- raster::extent(slippymath::lonlat_to_merc(as.matrix(expand.grid(x = my_bbox[c(1, 3)], y = my_bbox[c(2, 4)]))))
  out <- try(raster::crop(br, ex, snap = "out"), silent = TRUE)  ## FIXME how to avoid raster creating a file?
  if (inherits(out, "try-error")) {
    stop(sprintf("cannot read from WMTS url: %s", uzoom))  ## FIXME add longlat-bounds to message
  }
  suppressWarnings(raster::readAll(out))
}


