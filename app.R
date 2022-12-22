# ScholarlyOutput
# A shiny app to visualise a GoogleScholar profile
# https://github.com/JDLeongomez/ScolarlyOutput
# Juan David Leongómez - https://jdleongomez.info/

library(shiny)
library(thematic)
library(shinythemes)
library(colourpicker)
library(stringr)
library(scholar)
library(dplyr)
library(tidyr)
library(ggplot2)
library(ggpubr)
library(scales)
library(purrr) 

# Define UI for application that draws a histogram
ui <- fluidPage(theme = c("united"),

    # Application title
    titlePanel(title =
                 tags$link(rel = "icon", type = "image/gif", href = "img/icon.png"),
               "ScholarlyOutput"),
    tags$h1(HTML("<a style=color:#EA4335;  href='https://github.com/JDLeongomez/ScolarlyOutput'><b><i>ScolarlyOutput</b></i></a>")),
    tags$h4(HTML("Plot your scholarly output from <img src='https://upload.wikimedia.org/wikipedia/commons/2/28/Google_Scholar_logo.png' width='150'>")),
    tags$h6(HTML("App created in <a style=color:#EA4335;  href='https://shiny.rstudio.com/'>Shiny</a> by 
      <a style=color:#EA4335;  href='https://jdleongomez.info/es/'>Juan David Leongómez</a>
      · 2022 <br>
      Code available on
      <a style=color:#EA4335;  href='https://github.com/JDLeongomez/ScolarlyOutput'>GitHub</a>")),

    # Sidebar with a slider input for accent colour 
    fluidRow(
      column(3,
             hr(),
             p(HTML("This Shiny app gets publucations and citation information from
                    <a style=color:#EA4335;  href='https://scholar.google.com/'>Google Scholar</a>
                    using the 
                    <a style=color:#EA4335;  href='https://cran.r-project.org/web/packages/scholar/vignettes/scholar.html'>scholar</a> 
                    R package, and plots both the citations per publication (including <i>h</i>- 
                    and <i>g</i>-index; panel <b>A</b>), as well as the number of publications 
                    and citations per year (including total number of citations; panel <b>B</b>).")),
             hr(),
             tags$h4("Profile to plot"),
             textInput("profl",
                       "Please copy and paste your full Google Scholar profile URL:", 
                       value = "https://scholar.google.co.uk/citations?hl=en&user=8Q0jKHsAAAAJ", 
                       width = 600, 
                       placeholder = "https://scholar.google.co.uk/citations?hl=en&user=8Q0jKHsAAAAJ"), 
             h4("Save the Plot"),
             downloadButton("SavePlotPNG", label = "Save as PNG"),
             downloadButton("SavePlotPDF", label = "Save as PDF"),
             downloadButton("SavePlotSVG", label = "Save as SVG"),
             hr(),
             tags$h4("Graphical options"),
             colourInput("accentCol", 
                         "Accent colour (click to select):", 
                         "#EA4335",
                         returnName = TRUE),
             tags$h6(HTML("<b>Note:</b> alternatively, you can paste the  
                          name (e.g. <i><b>blue</b></i>) or
                          <a style=color:#EA4335;  href='https://g.co/kgs/Dsj3Za'>HEX value</a> 
                          (e.g. <b>#008080</b>) of a colour")),
             hr(),
             tags$h4("Filter publications"),
             tags$h6(HTML("I recommend doing some 
               <a style=color:#EA4335;  href='https://scholar.google.com/intl/es/scholar/citations.html#setup'>maintenance</a> 
               of your profile before creating this plot. This may include, for example, 
               merging duplicates and making sure that all relevant information, including 
               year, is complete and accurate. <br><br>
               Publications without date are automatically excluded from plots (but not 
               from the total citation count). However, because the quality of the plot 
               will be limited by the quality of the data, I have added an option to exclude 
               publications reported as published before a certain year.")),
             numericInput("minyear",
                          "Exclude publications dated before:", 
                          value = 1900,
                          min = 1,
                          max = lubridate::year(Sys.Date()),
                          width = 200),
             br(),
             br(),
             br(),
             #downloadLink("downloadPlot", "Download Plot")
      ),

      # Show a plot of the generated distribution
      column(6,
             offset = 1,
             br(),
             br(),
             plotOutput("scholarPlot")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    
    output$scholarPlot <- renderPlot(
      width = 1200,
      height = 600,
      res = 120,
      {
        #Define Scholar profile
        pfl <- input$profl %>% str_split(pattern = 'user\\=') %>%
          map_chr(c(2)) %>%
          str_sub(start = 1, end = 12)
        
        #Get data from Scholar (filtering specific non-academic publications)
        ##Publications
        pubs <- get_publications(pfl) %>%
          filter(!(journal == "" | journal == "target")) %>% 
          filter(!(year == "" | year < input$minyear))
        
        ##Citations
        ct <- get_citation_history(pfl)
        ##Full profile
        profile <- get_profile(pfl)
        
        #Create data frame
        ##Define years (from year of first publication to current year)
        years <- data.frame(year = c(min(pubs$year, na.rm = TRUE):as.numeric(format(Sys.Date(),'%Y'))))
        ##Get number of publications per year
        pd <- pubs %>%
          group_by(year) %>%
          summarise(pt = length(year)) %>%
          drop_na(year)
        ##Merge years and number of publications per year
        pt <- years %>%
          full_join(pd) %>%
          arrange(year)
        ##Add number of citations per year
        dat <- pt %>%
          full_join(ct) %>%
          arrange(year) %>%
          mutate(year = as.integer(year)) %>% 
          mutate(across(everything(), ~replace_na(.x, 0)))
        
        #Calculate metrics
        ##Get year to count last three years
        yearRecent <- as.integer(format(Sys.Date(), '%Y')) - 2
        ##Total number of citations
        citSum <- profile$total_cites
        ##Recent citations (last three years)
        citRecentSum <- ct %>%
          summarize(sumB = sum(cites[year >= yearRecent]))
        ##Number of publications with more than 50 citations
        count50cit <- nrow(ct[ct$cites > 50, ])
        ##Proportion of citation in the last three years
        citRecentProp <- citRecentSum/citSum
        
        #g-index and h-index
        ##g-index
        pubs$square <- as.numeric(row.names(pubs))^2
        pubs$sums <- cumsum(pubs$cites)
        g_index <- max(which(pubs$square < pubs$sums))
        ##h-index
        h_index <- profile$h_index
        ##Rank publications according to number of citations
        pubs$rank <- seq.int(nrow(pubs))
        ##Squared root of cumulative citations (rounded down)
        pubs$sqr <- floor(sqrt(pubs$sums))
        
        ##Define parameters for secondary axis
        ylim.prim <- c(0, max(dat$pt)*1.25)   # publications
        ylim.sec <- c(0, max(dat$cites))   # citations
        b <- diff(ylim.prim)/diff(ylim.sec)
        a <- ylim.prim[1] - b*ylim.sec[1]
        
        ## Define colors
        colors <- c("Citations per publication" = "black", "Square root of cumulative\ncitations (rounded down)" = "grey")
        
        #Plot 1: Citations per publication, h-index and g-index
        p1 <- ggplot(pubs, aes(x = rank, y = cites)) +
          geom_abline(intercept = 0, slope = 1, color = input$accentCol, linetype = "dotted", size = 0.7) +
          geom_line(aes(color = "Citations per publication")) +
          geom_line(aes(y = floor(sqrt(sums)), color = "Square root of cumulative\ncitations (rounded down)")) +
          scale_color_manual(values = colors) +
          geom_segment(aes(x = h_index, y = h_index, xend = h_index, yend = h_index+(g_index*0.5)),
                       size = 0.1, color = input$accentCol,
                       arrow = arrow(length = unit(0.3, "cm"), type = "closed")) +
          geom_segment(aes(x = g_index, y = g_index, xend = g_index, yend = g_index*1.5),
                       size = 0.1, color = input$accentCol,
                       arrow = arrow(length = unit(0.3, "cm"), type = "closed")) +
          annotate("text", y = h_index+(g_index*0.55), x = h_index,
                   label= bquote(italic(h)*'-'*index == .(h_index)),
                   hjust = 0, angle = 90,
                   color = input$accentCol, size = 3) +
          annotate("text", y = g_index*1.55, x = g_index,
                   label = bquote(italic(g)*'-'*index == .(g_index)),
                   hjust = 0, angle = 90,
                   color = input$accentCol, size = 3) +
          annotate("point", x = h_index, y = h_index,
                   color = input$accentCol) +
          annotate("point", x = g_index, y = g_index,
                   color = input$accentCol) +
          labs(x = "Publication (citation rank)",
               y = "Citations",
               subtitle = expression(paste("Citations per publication, ", italic(~h), "-index and", italic(~g), "-index"))) +
          theme_pubclean() +
          theme(axis.line.x = element_line(color = "grey"),
                axis.ticks.x = element_line(color = "grey"),
                axis.line.y.left = element_line(color = "black"),
                axis.ticks.y.left = element_line(color = "black"),
                axis.text.y.left = element_text(color = "black"),
                axis.title.y.left = element_text(color = "black"),
                legend.justification = c(1,1),
                legend.position = c(1,1),
                legend.title = element_blank(),
                legend.key = element_rect(fill = "transparent", colour = "transparent"),
                plot.subtitle = element_text(size = 9),
                axis.text = element_text(size = 6),
                axis.title = element_text(size = 8))
        
        #Plot2: Publications and citations per year
        ##Plot
        p2 <- ggplot(dat, aes(year, pt)) +
          geom_col(fill = "lightgrey") +
          geom_line(aes(y = a + cites*b), color = input$accentCol) +
          scale_x_continuous(breaks = pretty_breaks()) +
          scale_y_continuous("Publications", breaks = pretty_breaks(), sec.axis = sec_axis(~ (. - a)/b, name = "Citations")) +
          theme_pubclean() +
          annotate("text", y = Inf, x = -Inf,
                   label = paste0("Total citations = ", comma(profile$total_cites)),
                   vjust = 3, hjust = -0.1,
                   color = input$accentCol, size = 3) +
          theme(axis.line.x = element_line(color = "grey"),
                axis.ticks.x = element_line(color = "grey"),
                axis.line.y.right = element_line(color = input$accentCol),
                axis.ticks.y.right = element_line(color = input$accentCol),
                axis.text.y.right = element_text(color = input$accentCol),
                axis.title.y.right = element_text(color = input$accentCol),
                axis.line.y.left = element_line(color = "black"),
                axis.ticks.y.left = element_line(color = "black"),
                axis.text.y.left = element_text(color = "black"),
                axis.title.y.left = element_text(color = "black"),
                plot.subtitle = element_text(size=9),
                axis.text = element_text(size = 6),
                axis.title = element_text(size = 8)) +
          labs(x = "Year",
               subtitle = "Publications and citations per year")
        
        #Final plot
        p.fin <- ggarrange(p1, p2,
                           ncol = 2,
                           labels = "AUTO")
        
        ##Add date to final plot
        Sys.setlocale("LC_TIME", "C")
        annotate_figure(p.fin, 
                        bottom = text_grob(paste0("Data from Google Scholar. Plot updated ",
                                                  format(Sys.Date(),'%B %d, %Y')),
                                           hjust = 1.05, x = 1, size = 8),
                        top = text_grob(profile$name,
                                        face = "bold", hjust = -0.1, x = 0,  size = 14))
      })
    
    output$SavePlotPNG <- downloadHandler(
      filename = function(file) {
        "Scholar_profile.png"
        #ifelse(is.null(input$DataFile), return(), str_c(input$Title, ".png"))
      },
      content = function(file) {
        ggsave(file, width = 2400, height = 1200, units = "px", dpi = 300, device = "png")
      }
    )
    
    output$SavePlotPDF <- downloadHandler(
      filename = function(file) {
        "Scholar_profile.pdf"
        #ifelse(is.null(input$DataFile), return(), str_c(input$Title, ".png"))
      },
      content = function(file) {
        ggsave(file, width = 2400, height = 1200, units = "px", dpi = 300, device = "pdf")
      }
    )
    
    output$SavePlotSVG <- downloadHandler(
      filename = function(file) {
        "Scholar_profile.svg"
        #ifelse(is.null(input$DataFile), return(), str_c(input$Title, ".png"))
      },
      content = function(file) {
        ggsave(file, width = 2400, height = 1200, units = "px", dpi = 300, device = "svg")
      }
    )
}

# Run the application 
shinyApp(ui = ui, server = server)
