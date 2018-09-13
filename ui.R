# ------------- BluffBall - use bookie's odds to optimise fantasy premier league performance ----------------

library(shiny)
library(shinyLP)
library(shinydashboard)
library(shinythemes)
library(ggplot2)

# Get representation variables
vars <- readRDS('./Utils/representation variables.rds')

# Define UI for application
shinyUI(tagList(
  tags$head(
    tags$style(
      HTML(".shiny-notification {
           height: 100px;
           width: 800px;
           position:fixed;
           top: calc(50% - 50px);;
           left: calc(50% - 400px);;
           }"
                    )
      )
      ),
  dashboardPage(skin = 'red',
                
                
                
                # ---- Set up dashboard layout ----
                dashboardHeader(title = 'SimpleSampler'),
                
                # Side bar
                dashboardSidebar(
                  sidebarMenu(
                    menuItem("Home", tabName = "home", icon = icon("home")),
                    menuItem("Draw samples", tabName = "sample", icon = icon("dashboard"))
                  )
                ),
                
                # Dashboard content
                dashboardBody(
                  #tags$head(HTML(includeText('google-analytics.js'))),
                  tabItems(
                    
                    # ---- Landing page ----
                    tabItem("home",
                            
                            jumbotron("SimpleSampler",
                                      em("Quickly draw nationally representative school samples for social research"),
                                      button = FALSE
                            ),
                            br(),
                            fluidRow(
                              box(width = 12,
                                  title = 'Welcome',
                                  status = 'danger',
                                  solidHeader = T,
                                  h3('Sampling made easy'),
                                  br(),
                                  p('Use this tool when you want to get a nationally representative sample of school to contact for social research 
                                    (e.g. for a survey, or deep dive interviews). You choose how accurate you want your survey results to be, or 
                                    how many schools you can afford to contact. SimpleSampler will download the latest set of information about
                                    schools and automatically draw a nationally representive sample from it according to your specification.'),
                                  br(),
                                  HTML('Go to the <b>Draw sample</b> tab to get started')
                              )
                              
                            )
                    ),
                    
                    # ---- Draw and display samples ----
                    tabItem(tabName = 'sample',
                            h2("Draw samples"),
                            HTML("To draw a sample, you'll need to specify either a <b>margin for error</b> 
                              or a <b>desired sample size</b>, enter some basic settings, and then click 'Go'."),
                            p(),
                            fluidRow(
                              tabBox(
                                title = "Specification",
                                id = "spec",
                                width = 6,
                                side = "left",
                                tabPanel("Margin for error",
                                         h3("What does this mean?"),
                                         p("One way of drawing a sample is to specify what margin for error 
                                           you would be happy with in the final survey results. Let's take an example. 
                                           Imagine your survey asks schools whether they are happy with a policy, and 50% say yes. 
                                           If you chose a margin for error of 5 percentage points, this means that we are confident the 
                                           true proportion of schools in the population that are happy with the policy is between 45% and 50%."),
                                         p("If you want a smaller margin for error, you'll need a bigger sample (and vice versa)."),
                                         sliderInput(inputId ='ci',
                                                     label ='Select margin for error (percentage points)', 
                                                     min = 1,
                                                     max = 10, 
                                                     step = 0.1,
                                                     value = 5)
                                ),
                                tabPanel("Sample size",
                                         h3("What does this mean?"),
                                         p("The other way of drawing a sample is to specify how big you want the sample to be. This is more
                                            useful when you can only afford to contact a certain number of schools."),
                                         p("The smaller your sample, the larger your margin for error."),
                                         sliderInput(inputId ='sampsize',
                                                     label ='Select sample size', 
                                                     min = 100,
                                                     max = 5000, 
                                                     step = 10,
                                                     value = 1000)
                                )
                              ),
                              
                              box(title = "Settings",
                                  width = 6,
                                  h3("Choose expected response rate and representation characteristics"),
                                  p("Tell SimpleSampler what you expect your response rate to be, and what 
                                    characteristics you want your sample to be nationally representative on."),
                                  sliderInput(inputId = 'rate',
                                              label = 'Response rate',
                                              min = 5,
                                              max = 50,
                                              value = 25, 
                                              post = "%"),
                                  selectizeInput(inputId = 'repr',
                                                 label = 'Representation characteristics',
                                                 choices = vars,
                                                 selected = vars[c(2,5,6,9,10)],
                                                 multiple = TRUE),
                                  p()
                                  )
                      ),
                      fluidRow(
                        box(title = "Draw sample",
                            actionButton('drawsample', 'Go!'))
                      ),
                      fluidRow(
                        infoBox("Margin for error", 
                                value = textOutput('ci'), 
                                icon = icon("cog"),
                                color = "yellow"),
                        infoBox("Sample size", 
                                value = textOutput('sampsize'), 
                                icon = icon("table"),
                                color = "yellow"),
                        infoBox("Expected responses", 
                                value = textOutput('expresp'), 
                                icon = icon("star"),
                                color = "yellow")
                      ),
                      fluidRow(
                        box(title = "Results",
                            width = 12,
                            solidheader = TRUE,
                            h3("Primary sample"),
                            dataTableOutput('prisamptab'),
                            downloadButton('downloadPri', 'Save sample'),
                            p(),
                            h3("Secondary sample"),
                            p(),
                            dataTableOutput('secsamptab'),
                            downloadButton('downloadSec', 'Save sample'))
                      )
                      
                    )
                    
                    
                  )
                  
                  
                )
            ) # End dashboardPage
  
  
  
) # End taglist
) # End shiny ui
