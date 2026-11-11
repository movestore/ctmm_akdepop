# Population Autocorrelated Kernel Density Estimate (pKDE)

MoveApps

GitHub repository: https://github.com/movestore/ctmm_akdepop

<p align="center">
  <img alt="Maps of the distribution of the sample and of the population" src="readme_thumbnail.png" width="700">
</p>

## Description
Estimate the mean home range area of an individual, the joint home range of
the tracked animals in the sample, and the range of the whole population from
the aKDE home ranges of a set of tracked animals.

## Documentation
This App uses the autocorrelated kernel density estimates (aKDEs) of several
tracked animals to make population-level estimates. It calculates three
things:

1. **The mean home range area of an individual** in the population, with a
   confidence interval.
2. **The distribution of the sample**: the joint home range of the sample of
   tracked animals.
3. **The distribution of the population**: the estimated range of the whole
   population, accounting for the fact that the tracked animals constitute
   a sample of the overall population.

This App is part of a ctmm Workflow. You must run the *Autocorrelated
Kernel Density Estimate (aKDE)* App before this one, as its output is
necessary to calculate the population estimates.

See the ctmm documentation of [`meta()`][1], [`pkde()`][2] and the
[`mean()` method for UDs][3] for more details on the methods.

[1]: https://ctmm-initiative.github.io/ctmm/reference/meta.html
[2]: https://ctmm-initiative.github.io/ctmm/reference/akde.html
[3]: https://ctmm-initiative.github.io/ctmm/reference/mean.html

### Application scope
#### Generality of App usability
This App was developed for any taxonomic group that displays range-resident
behavior.

#### Required data properties
This App is only applicable to data that reflect range-resident behavior. Use
the *Variogram* App to evaluate whether this property holds for your data.

The input must contain at least 2 animals.

### Input type
`ctmm ud with data`: a list with three elements, as produced by the
*Autocorrelated Kernel Density Estimate (aKDE)* App:

1. `model`: a list containing the selected `ctmm` model for each animal.
2. `uds`: a list containing the aKDE utilization distribution (UD, an object
   of class `UD`) for each animal.
3. `data`: the tracking data (an object of type `telemetry.list`).

### Output type
`ctmm ud with data`: the input, unchanged.

### Artefacts
`akdepop_summary.csv`: a table of the three area estimates. It contains the
following columns:
  - `parameter`: the area being estimated and its unit (always square meters).
    One of:
    - `mean_individual_area`: the mean 95% home range area of an individual
      in the population (from `ctmm::meta()`).
    - `sample_range_area`: the 95% area of the distribution of the sample,
      i.e. the joint home range of the tracked animals.
    - `population_range_area`: the 95% area of the distribution of the
      population, i.e. the estimated range of the whole population (from
      `ctmm::pkde()`).
  - `description`: a short description of the parameter.
  - `low`, `est`, `high`: the estimated area and the lower and upper bounds of
    its 95% confidence interval.

`akdepop_summary.pdf`: a comparison of the home range areas for each animal,
along with their 95% confidence intervals. The bottom row (`mean`) shows the
mean home range area of an individual (this is `mean_individual_area` from
`akdepop_summary.csv`).

`dist_of_sample_and_pop.pdf`: maps showing the distribution of the sample and
the distribution of the population. Each map shows the tracked locations, the
density of the distribution, the 95% contour line, and its confidence
interval.

`dist_sample.gpkg`, `dist_pop.gpkg`: GeoPackages showing the 95% isopleth
of the distribution of the sample and of the population, respectively.
Each contains three polygons: the estimate and the lower and upper bounds
of its 95% confidence interval. The coordinates are in the local map
projection that ctmm uses for the tracking data.

`dist_sample.tif`, `dist_pop.tif`: the utilization distribution of the sample
and of the population, respectively, as GeoTIFF rasters. Each cell's value is
the probability that a randomly chosen animal will be found within the contour
line passing through that cell. The coordinates are in the local map
projection that ctmm uses for the tracking data.

### Settings
This App has no settings.

### Changes in output data
The input data remain unchanged.

### Errors and null handling
**Fewer than 2 animals:** Population-level estimates need at least 2 animals.
If the input contains only one, the App stops with an error.

**Performance:** The App fits a population model to the individual models,
which can take a while for data sets with many animals.

### Technical details
The mean home range area of an individual is calculated with
[`ctmm::meta()`][1] from the 95% home range areas of the individual UDs. The
distribution of the sample is the average of the individual UDs, calculated
with ctmm's [`mean()` method for UDs][3]. The distribution of the population
is calculated with [`ctmm::pkde()`][2] from the tracking data and the
individual UDs.

The areas are calculated with ctmm's `summary()` method for UDs, the contours
with `ctmm::SpatialPolygonsDataFrame.UD()` and the rasters with ctmm's
`writeRaster()` method for UDs.

Note: ctmm 1.3.x does not mark holes within a contour. This App identifies
nested contour rings so that areas inside the outer contour that are not part
of the distribution at the 95% level are left out of the output polygons.

The population-level inference of home range areas is described in Fleming,
C. H., Deznabi, I., Alavi, S., Crofoot, M. C., Hirsch, B. T., Medici, E. P.,
Noonan, M. J., Kays, R., Fagan, W. F., Sheldon, D., & Calabrese, J. M.
(2022). Population-level inference for home-range areas. *Methods in Ecology
and Evolution*, 13(5), 1027–1041. https://doi.org/10.1111/2041-210X.13815

The aKDE method is described in Fleming, C. H., Fagan, W. F., Mueller, T.,
Olson, K. A., Leimgruber, P., & Calabrese, J. M. (2015). Rigorous home range
estimation with movement data: A new autocorrelated kernel density estimator.
*Ecology*, 96(5), 1182–1188. https://doi.org/10.1890/14-2010.1

The ctmm package is described in Calabrese, J. M., Fleming, C. H., &
Gurarie, E. (2016). ctmm: An R package for analyzing animal relocation data as
a continuous-time stochastic process. *Methods in Ecology and Evolution*,
7(9), 1124–1132. https://doi.org/10.1111/2041-210X.12559
