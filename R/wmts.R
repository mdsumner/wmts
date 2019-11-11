#' OGC Webmap Tile Server (WMTS)
#'
#' Get raster from WMTS
#'
#' @param x WMTS address
#' @param loc something we can get an extent from
#' @param buffer radius in metres (in the case 'loc' is a single point)
#' @param ... ignored
#' @param zoom override hueristic for zoom level (take care! no safety checks)
#' @param max_tiles max number of tiles for zoom hueristic (default 25)
#' @param bands bands to get (default is 1,2,3 assuming RGB)
#' @export
#' @return raster brick
#' @examples
#' centre <- c(-9004415, 3806965)
#' radius <- 4000
#' u <- "WMTS:https://basemap.nationalmap.gov/arcgis/rest/services/USGSTopo/MapServer/WMTS/1.0.0/WMTSCapabilities.xml,layer=USGSTopo,tilematrixset=default028mm"
#' x <- wmts(u, centre, radius)
#' #ex <- raster::extent(centre[c(1, 1, 2, 2)] + c(-1, 1, -1, 1) * buffer)
#' #rgb_map <- plot_get_wmts(l, ex, native = TRUE)
#' #
#' #library(ggplot2)
#' #
#' #tab <- tibble::as_tibble(as.data.frame(rgb_map, xy = TRUE))
#' #names(tab) <- c("x", "y", "red", "green", "blue")
#' ##tab <- dplyr::filter(tab, !is.na(red))
#' #
#' ### ... when we have missing values, we should drop them or rgb() will error
#' #tab$hex <- rgb(tab$red, tab$green, tab$blue, maxColorValue = 255)
#' #ggplot(tab, aes(x, y, fill = hex)) +
#' #  geom_raster() +
#' #  coord_equal() +
#' #  scale_fill_identity()
wmts <- function(x, loc, buffer = NULL, ..., zoom = NULL, max_tiles = 25, bands = 1:3) {
  #pts <-  slippymath::merc_to_lonlat(matrix(centre, ncol = 2L))
  bbox_pair <- spatial_bbox(x, buffer)
  my_bbox <- bbox_pair$tile_bbox
  bb_points <- bbox_pair$user_points
  ## all we need is zoom
  tile_grid <- slippymath::bbox_to_tile_grid(my_bbox, max_tiles = max_tiles,
                                           zoom = zoom)
  zoom_level <- tile_grid$zoom
  if (!is.null(zoom)) zoom_level <- zoom
  br <- raster::subset(raster::brick(paste0(x, sprintf(",zoom_level=%i", zoom_level))), bands)
  ex <- raster::extent(slippymath::lonlat_to_merc(as.matrix(expand.grid(x = my_bbox[c(1, 3)], y = my_bbox[c(2, 4)]))))
  raster::crop(br, ex)
}


