u <- file.path("https://basemap.nationalmap.gov/arcgis/rest",
                "services/USGSTopo/MapServer/WMTS/1.0.0/WMTSCapabilities.xml")
u1 <- sprintf("WMTS:%s,layer=USGSTopo,tilematrixset=default028mm", u)
test_that("wmts works", {
  rgb <- wmts(u1, cbind(-100, 30)) %>% expect_s4_class("RasterBrick")
  rgba <- wmts(u1, cbind(-100, 30), bands = 1:4, silent = TRUE, max_tiles = 4) %>% expect_s4_class("RasterBrick")
  expect_equal(raster::nlayers(rgba), 4L)
  expect_equal(raster::nlayers(rgb), 3L)

  expect_warning(wmts(u1, cbind(-100, 30)))
  expect_error(wmts(u, cbind(-100, 30), 5000, sds = 3))

 r <- raster::raster(  system.file("extdata/sst.tif", package = "vapour", mustWork = TRUE))
  a <- expect_s4_class(wmts(u1, r, zoom = 3), "RasterBrick")

})
