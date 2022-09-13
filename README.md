# ScolarlyOutput

**ScolarlyOutput** is a small R Shiny app for creating amd exporting a complete plot of your academic [**Google Scholar**](https://scholar.google.com/) profile.

It only requires the full link to your Google Scholar profile (just copy it and paste it in the box), and it will create a plot with your name (as it appears on your Google Scholar profile) and two panels:

<ol type="A">
  <li>Citations per publication (including h- and g-index)</li>
  <li>Number of publications and citations per year (including total number of citations)</li>
</ol>

You can change an accent color and filter publications. 

The final plot can be exported to PNG, PDF and SVG formats.

Below is an example of the ScolarlyOutput plot of my own profile.

![ScolarlyOutput Example](img/ScolarlyOutput.jpg)

It uses the fantastic [<code>scholar</code>](https://cran.r-project.org/web/packages/scholar/vignettes/scholar.html) R package to extract the info from your Google Scholar profile, and then several [<code>tidyverse</code>](https://www.tidyverse.org/) packages (most notably [<code>ggplot2</code>](https://ggplot2.tidyverse.org/)) to wrangle and plot these data. 

## How to run it

Sadly, the [<code>scholar</code>](https://cran.r-project.org/web/packages/scholar/vignettes/scholar.html) package cannot be updated and run from a server like shinyapps.io, so it must be run localy in your computer. 

To do so, simply clone or [download](https://github.com/JDLeongomez/ScolarlyOutput/archive/refs/heads/main.zip) the [**ScolarlyOutput**](https://github.com/JDLeongomez/ScolarlyOutput) repository. 

**You must have the shiny package installed**, so that once you open the [<code>app.R</code>](https://github.com/JDLeongomez/ScolarlyOutput/blob/main/app.R) file In RStudio, you can simply click the **Run App** button.

## Why I made this super small app

I originally created the code to download data from Google Scholar and make these plots for a particular version of my CV. However, several friends liked it and wanted to make plots of their own profiles, so I decided to turn it into a Shiny App for anyone to use.