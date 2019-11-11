
<!-- README.md is generated from README.Rmd. Please edit that file -->

# wmts

<!-- badges: start -->

<!-- badges: end -->

The goal of wmts is to …

NOT USEABLE yet, watch out

  - will create temporary files (gdalwmscache, and raster temp)
  - no checks for in-bounds for tiles
  - no safety checks if you manually set a large zoom
  - no idea what systems/OS this works on yet (tested on Ubuntu)

## TODO

  - \[x\] need to deal with various inputs (how does ceramic do it,
    missing something atm)
  - \[ \] add providers

## Example

``` r
## remotes::install_github("mdsumner/wmts")
centre <- c(-80.888, 32.332)  ## lonlat
radius <- 4000                ## metres
u <- "WMTS:https://basemap.nationalmap.gov/arcgis/rest/services/USGSTopo/MapServer/WMTS/1.0.0/WMTSCapabilities.xml,layer=USGSTopo,tilematrixset=default028mm"
library(wmts)
x <- wmts(u, centre, buffer = radius)
#> zoom: 14
raster::plotRGB(x)
```

<img src="man/figures/README-example-1.png" width="100%" />

``` r
#f <- system.file("gpkg/nc.gpkg", package = "sf", mustWork = TRUE)
#sf <- sf::read_sf(f)
#x <- wmts(u, sf)
tab <- tibble::as_tibble(raster::as.data.frame(x, xy = TRUE))
names(tab) <- c("x", "y", "red", "green", "blue")
##tab <- dplyr::filter(tab, !is.na(red))  ##... when we have missing values, we should drop them or rgb() will error
tab$hex <- rgb(tab$red, tab$green, tab$blue, maxColorValue = 255)
library(ggplot2)
ggplot(tab, aes(x, y, fill = hex)) +
  geom_raster() +
  coord_equal() +
  scale_fill_identity()
```

<img src="man/figures/README-example-2.png" width="100%" />

-----

Please note that the wmts project is released with a [Contributor Code
of
Conduct](https://contributor-covenant.org/version/1/0/0/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
