is_http_generic <- function(x) {
  grepl("^http", x, ignore.case = TRUE)
}
gdalsource_handler <- function(x, sds = 1, ...) {
  ## x might be
  ##      URL https://basemap.nationalmap.gov/arcgis/rest/services/USGSTopo/MapServer/WMTS/1.0.0/WMTSCapabilities.xml
  ##      DSN WMTS:https://basemap.nationalmap.gov/arcgis/rest/services/USGSTopo/MapServer/WMTS/1.0.0/WMTSCapabilities.xml,layer=USGSTopo,tilematrixset=default028mm
  ## If URL, need SDS choice
  ## (what if it's ecwp:// ?)
  if (is_http_generic(x)) {
    subds <- vapour::vapour_sds_names(x)
    if (sds > 1 || sds < 0 || sds > length(subds[["subdataset"]])) {
      stop(sprintf("'sds' must be 1 or larger, there are %i subdatasets", length(subds[["subdataset"]])))
    }
    if (length(sds) > 1) warning("only one subdataset can be accessed at a time, 'sds[1]' will be used")
    x <- subds[["subdataset"]][sds[1]]
  } else {
    ## we assume you've declared the DRIVER:<url>[,option1][,option2]etc.
  }

  x
}

#' OGC Webmap Tile Server (WMTS)
#'
#' Get raster from WMTS
#'
#' Beware that if 'zoom' is set the 'max_tiles' argument is ignored. Use
#' the function defaults to discover a reasonable zoom level, then re-run with a
#' higher (more pixels) or lower (fewer pixels) zoom level.
#' @param x WMTS address, either the raw 'WMTSCapabilities.xml' or an expanded GDAL 'WMTS:<url>[],options]' driver data source
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
#' # x <- wmts("https://basemap.nationalmap.gov/arcgis/rest/services/USGSTopo/MapServer/WMTS/1.0.0/WMTSCapabilities.xml", centre, buffer = radius)
#' # x <- wmts(u, cbind(0, 0), buffer = 20037508)
#' raster::plotRGB(x, interpolate = TRUE) ## use interpolate to match to device size
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
#' #   geom_raster(interpolate = TRUE) +
#' #   coord_equal() +
#' #   scale_fill_identity()
wmts <- function(x, loc, buffer = NULL, silent = FALSE, ..., zoom = NULL, max_tiles = 9, bands = 1:3) {
  x <- gdalsource_handler(x)
  if (is.numeric(loc)) loc <- matrix(loc, byrow = TRUE, ncol = 2)
  bbox_pair <- spatial_bbox(loc, buffer)
  my_bbox <- bbox_pair$tile_bbox
  bb_points <- bbox_pair$user_points
  ## all we need is zoom
  if (!is.null(zoom))   max_tiles <- NULL
  tile_grid <- slippymath::bbox_to_tile_grid(my_bbox, max_tiles = max_tiles,
                                           zoom = zoom)
  zoom_level <- tile_grid$zoom
  if (!is.null(zoom)) {
    zoom_level <- zoom
  }
  if (!silent) {
    writeLines(sprintf("zoom: %s", zoom_level))
  }
  uzoom <- paste0(x, sprintf(",zoom_level=%i", zoom_level))
  ex <- raster::extent(slippymath::lonlat_to_merc(as.matrix(expand.grid(x = my_bbox[c(1, 3)], y = my_bbox[c(2, 4)]))))
 br <- raster::subset(raster::brick(uzoom), bands)
    out <- try(raster::crop(br, ex, snap = "out"), silent = TRUE)  ## FIXME how to avoid raster creating a file?

  if (inherits(out, "try-error")) {
    stop(sprintf("cannot read from WMTS url: %s", uzoom))  ## FIXME add longlat-bounds to message
  }
  suppressWarnings(raster::readAll(out))
}


