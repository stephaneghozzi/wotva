<!-- omit in toc -->
# WHO Outbreak Toolkit Virtual Assistant

- [Overview](#overview)
- [How to load data](#how-to-load-data)
- [Issues and TODOs](#issues-and-todos)
- [Session information](#session-information)
- [Contributions](#contributions)
- [Licence](#licence)

## Overview

Prototype of a tool to help the investigation of outbreaks of unknown origins, developed for the [Outbreak Toolkit](https://www.who.int/emergencies/outbreak-toolkit) of the [World Heath Organization](https://www.who.int).

*description coming soon*

A live version of the dashboard is accessible at https://stephaneghozzi.shinyapps.io/wotva

The approach, results and perspectives are presented in doc/outbreak_toolkit-assistant-presentation-20191016-long.pdf and doc/report-nopreprocessing.pdf (with a slightly outdated version of the dashboard).

The different processing steps and functions are presented in vignette/vignette.html. The sources for the functions are found in src/.

<img src="img/wotva-screenshot.png" alt="wotva screenshot" width="400" class="center"/>

## How to load data

*description coming soon*

## Issues and TODOs

- Cache the results (scores and dimensionality reduction).
- Reset references when a new data dictionary is selected, reset case data (line list) when new references are selected.
- Improve the computation speed of distances.

## Session information

The dashboard deployed on https://stephaneghozzi.shinyapps.io/wotva was built with:

```
R version 3.6.1 (2019-07-05)
Platform: x86_64-apple-darwin15.6.0 (64-bit)
Running under: OS X El Capitan 10.11.6

Matrix products: default
BLAS:   /System/Library/Frameworks/Accelerate.framework/Versions/A/Frameworks/vecLib.framework/Versions/A/libBLAS.dylib
LAPACK: /Library/Frameworks/R.framework/Versions/3.6/Resources/lib/libRlapack.dylib

locale:
[1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods  
[7] base     

other attached packages:
 [1] dplyr_0.8.3           Rtsne_0.15           
 [3] DT_0.9                rpivotTable_0.3.0    
 [5] leaflet_2.0.2         plotly_4.9.0         
 [7] ggplot2_3.2.1         ISOweek_0.6-2        
 [9] shinycssloaders_0.2.0 shinydashboard_0.7.1 
[11] shiny_1.4.0          

loaded via a namespace (and not attached):
 [1] tidyselect_0.2.5   purrr_0.3.2        colorspace_1.4-1  
 [4] vctrs_0.2.0        htmltools_0.4.0    viridisLite_0.3.0 
 [7] yaml_2.2.0         rlang_0.4.0        later_1.0.0       
[10] pillar_1.4.2       glue_1.3.1         withr_2.1.2       
[13] RColorBrewer_1.1-2 lifecycle_0.1.0    stringr_1.4.0     
[16] munsell_0.5.0      gtable_0.3.0       htmlwidgets_1.5.1 
[19] labeling_0.3       fastmap_1.0.1      httpuv_1.5.2      
[22] crosstalk_1.0.0    Rcpp_1.0.2         xtable_1.8-4      
[25] promises_1.1.0     scales_1.0.0       backports_1.1.4   
[28] jsonlite_1.6       mime_0.7           digest_0.6.21     
[31] stringi_1.4.3      grid_3.6.1         tools_3.6.1       
[34] magrittr_1.5       lazyeval_0.2.2     tibble_2.1.3      
[37] crayon_1.3.4       tidyr_1.0.0        pkgconfig_2.0.3   
[40] zeallot_0.1.0      data.table_1.12.2  assertthat_0.2.1  
[43] httr_1.4.1         rstudioapi_0.9.0   R6_2.4.0          
[46] compiler_3.6.1    
```

## Contributions

Conception and development: Stéphane Ghozzi

Conception, data dictionary, references: Lucas Deroo, Anne Perrocheau, Karl Schenkel

Funding: [INIG](https://www.rki.de/EN/Content/Institute/DepartmentsUnits/ZIG/INIG/INIG_node.html) of the [Robert Koch Institute](https://www.rki.de) and MDC of WHO.

## Licence

The code is made available under a [CC0](https://creativecommons.org/share-your-work/public-domain/cc0/) licence, i.e. others may freely build upon, enhance and reuse the works for any purposes without restriction under copyright or database law.