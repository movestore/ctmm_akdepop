library(ctmm)
library(sf)

# Generate contour polygons for a UD at the given isopleth level. This ensures
# that internal holes within the contours are correctly left unfilled. At the
# time of writing, there is a bug in ctmm (1.3.x) that does not mark these
# holes correctly, meaning that the entire region within the external contour
# is filled.
ud_contours <- function(ud, level.UD) {
  spdf <- ctmm::SpatialPolygonsDataFrame.UD(ud, level.UD = level.UD)

  # Use even-odd rule to identify holes. Contour rings are nested by definition,
  # so the symmetric difference of all rings keeps the area inside an odd
  # number of rings and drops the areas inside an even number (holes).
  geometries <- lapply(spdf@polygons, function(contour) {
    rings <- lapply(contour@Polygons, function(ring) sf::st_polygon(list(ring@coords)))
    geom <- Reduce(sf::st_sym_difference, rings)

    # Rings that touch can leave zero-width line fragments in the result.
    # Keep only the polygon parts.
    if (inherits(geom, "GEOMETRYCOLLECTION")) {
      geom <- sf::st_union(sf::st_collection_extract(sf::st_sfc(geom), "POLYGON"))[[1]]
    }

    sf::st_cast(geom, "MULTIPOLYGON")
  })

  # Rebuild output to mirror `ctmm::SpatialPolygonsDataFrame.UD()` structure.
  # Contour names are the ctmm polygon `ID` values.
  sf::st_sf(
    name = vapply(spdf@polygons, function(contour) contour@ID, character(1)),
    geometry = sf::st_sfc(geometries, crs = sf::st_crs(spdf@proj4string))
  )
}

rFunction <- function(data) {
  # Population-level estimates need at least 2 individuals. With only one,
  # ctmm still returns results, but the population range is meaningless
  # (it collapses to a tiny area around the locations).
  n_ind <- length(data[[2]])
  if (n_ind < 2) {
    stop(
      "The input contains ", n_ind, " individual(s). Population-level ",
      "home-range estimates require UDs of at least 2 individuals."
    )
  }

  # Plot of each individual's home-range area and the population mean. The
  # numbers for the summary table are taken from a second call below, which
  # returns them in square meters (with units = TRUE ctmm picks the unit itself)
  pdf(appArtifactPath("akdepop_summary.pdf"))
  ctmm::meta(data[[2]], plot = TRUE)
  dev.off()
  meta <- ctmm::meta(data[[2]], plot = FALSE, units = FALSE)
  
  # pop means
  MEAN <- mean(data[[2]]) # distribution of the sample
  PKDE <- pkde(data[[3]], data[[2]]) # distribution of the population
  
  # Side-by-side maps of sample and population distributions
  EXT <- extent(list(MEAN, PKDE))
  ids <- sapply(data[[3]], function(tel) tel@info$identity)
  COL <- grDevices::hcl.colors(n_ind, palette = "Dark 3")

  pdf(appArtifactPath("dist_of_sample_and_pop.pdf"), width = 11, height = 5)
  layout(matrix(1:3, nrow = 1), widths = c(1, 1, 0.4))
  plot(data[[3]], MEAN, col = COL, ext = EXT)
  title("Distribution of the sample")
  plot(data[[3]], PKDE, col = COL, ext = EXT)
  title("Distribution of the population")
  par(mar = c(0, 0, 0, 0))
  plot.new()
  legend(
    "center", legend = ids, col = COL, pch = 19, bty = "n",
    ncol = ceiling(n_ind / 25), cex = if (n_ind > 25) 0.7 else 1
  )
  dev.off()
  
  # Summary table of the three area estimates (95% contour, with 95% CIs).
  # units = FALSE reports all areas in square meters so they are comparable
  # (ctmm would otherwise pick a unit for each one separately).
  ci_m2 <- rbind(
    meta[1, , drop = FALSE],                         # row "mean" of meta()
    summary(MEAN, units = FALSE)$CI[1, , drop = FALSE],
    summary(PKDE, units = FALSE)$CI[1, , drop = FALSE]
  )

  summary_table <- data.frame(
    parameter = c(
      "mean_individual_area (square meters)",
      "sample_range_area (square meters)",
      "population_range_area (square meters)"
    ),
    description = c(
      "Mean home-range area of an individual in the population (ctmm::meta)",
      "Area of the combined range of the tracked individuals (mean of their UDs)",
      "Estimated range area of the whole population, including untracked individuals (ctmm::pkde)"
    ),
    low = ci_m2[, "low"],
    est = ci_m2[, "est"],
    high = ci_m2[, "high"]
  )
  write.csv(summary_table, appArtifactPath("akdepop_summary.csv"), row.names = FALSE)

  # ctmm labels the contour polygons with the UD's identity. For these UDs that
  # would be all animal names joined together (sample) or the name of the first
  # animal (population), so give them clear names instead.
  MEAN@info$identity <- "sample"
  PKDE@info$identity <- "population"

  ud_contours(MEAN, level.UD = 0.95) |>
    sf::st_write(appArtifactPath("dist_sample.gpkg"), append = FALSE)
  
  ud_contours(PKDE, level.UD = 0.95) |>
    sf::st_write(appArtifactPath("dist_pop.gpkg"), append = FALSE) 
  
  writeRaster(MEAN, appArtifactPath("dist_sample.tif"), overwrite = TRUE)
  writeRaster(PKDE, appArtifactPath("dist_pop.tif"), overwrite = TRUE)
  
  return(data)
  
}
