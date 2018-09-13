# ------------- BluffBall - use bookie's odds to optimise fantasy premier league performance ----------------

library(shiny)
library(ggplot2)
library(dplyr)

options(shiny.usecairo=T, digits = 2)

# Setup
date <- Sys.Date()
month <- ifelse(nchar(month(date)) == 1, paste0("0", month(date)), month(date))
day <- ifelse(nchar(day(date)) == 1, paste0("0", day(date)), day(date))

# Define server logic
shinyServer(function(input, output) {
  
  # Get edubase data on click
  edubase <- eventReactive(input$drawsample, {
    
    # Progress bar
    withProgress(message = 'Downloading latest school dataset',
                 detail = 'This usually takes around 30 seconds', value = 0, {
                   
                   # Download
                   edubase <- fread(paste0('http://ea-edubase-api-prod.azurewebsites.net/edubase/edubasealldata',
                                year(date),
                                month,
                                day,
                                '.csv'))  
                   setProgress(0.5)
                   
                   # Manipulate
                   edubase.2 <- edubase %>%
                     filter(`EstablishmentStatus (name)` == "Open") %>%
                     select(URN,
                            EstablishmentName,
                            TelephoneNum,
                            HeadFirstName,
                            HeadLastName,
                            type = `TypeOfEstablishment (name)`,
                            group = `EstablishmentTypeGroup (name)`,
                            OpenDate,
                            phase = `PhaseOfEducation (name)`,
                            gender=`Gender (name)`,
                            NumberOfPupils,
                            PercentageFSM,
                            trusts = `Trusts (name)`,
                            Ofsted = `OfstedRating (name)`,
                            Town,
                            Postcode,
                            region = `GOR (name)`) %>%
                     mutate(region = as.factor(region),
                            Ofsted = as.factor(Ofsted),
                            region2 = ifelse(region == "London", "London", "Non-London"),
                            phase2 = case_when(phase == "Primary" | phase == "Middle deemed primary" ~ "Primary",
                                               phase == "Secondary" | phase == "Middle deemed secondary" ~ "Secondary",
                                               TRUE ~ "Other")) %>%
                     group_by(phase2) %>%
                     mutate(numpupils_quintile = ntile(NumberOfPupils, 5),
                            fsm_quintile = ntile(PercentageFSM, 5)) %>%
                     ungroup %>%
                     filter(region != "Not Applicable", region != "Wales (pseudo)")
                 })
    
    return(edubase.2)
    
  }) 
  
  # Get confidence interval
  c <- reactive(input$ci/100)
  
  # Get sample size
  x <- reactive(input$sampsize)
  
  # Display confidence interval
  output$ci <- renderText({
    # Check specification
    if(input$spec == "Margin for error") {
      ci = input$ci
    } else {
      ci = 100 * sqrt((1.96 * 0.5 * 0.5)/(x() * input$rate/100))
    }
    
    # Format
    ci <- round(ci, 1)
    ci <- paste0("+/- ", ci, " percentage points")
    return(ci)
  })
  
  # Display sample size
  output$sampsize <- renderText({
    
    # Check specification
    if(input$spec == "Margin for error") {
      n = round((1.96 * 0.5 * 0.5)/c()^2)/(input$rate/100)
    } else {
      n = x()
    }
    
    # Format
    n <- paste(round(n))
    return(n)
  })
  
  # Display expected responses
  output$expresp <- renderText({
    
    # Check specification
    if(input$spec == "Margin for error") {
      n = round((1.96 * 0.5 * 0.5)/c()^2)
    } else {
      n = x() * (input$rate/100)
    }
    
    # Format
    n <- paste(round(n))
    return(n)
  })
  
  # Set variables you want to be representative by
  repr <- reactive(input$repr)
  
  # Draw secondary sample
  secsamp <- reactive({
    
    # Check specification
    if(input$spec == "Margin for error") {
      n = round((1.96 * 0.5 * 0.5)/c()^2)/(input$rate/100)
    } else {
      n = x()
    }
    
    # Get representation vars
    repr <- as.character(repr())
    
    # Get data
    df <- edubase()
    
    # Secondary
    df %>%
      filter(phase2 == "Secondary") %>%
      group_by_(repr) %>%
      sample_frac(n/nrow(.)) %>%
      ungroup %>%
      mutate_at(vars(repr), as.factor)
    
  })
  
  # Draw primary sample
  prisamp <- reactive({
    
    # Check specification
    if(input$spec == "Margin for error") {
      n = round((1.96 * 0.5 * 0.5)/c()^2)/(input$rate/100)
    } else {
      n = x()
    }
    
    # Get representation vars
    repr <- as.character(repr())
    
    # Get data
    df <- edubase()
    
    # Secondary
    df %>%
      filter(phase2 == "Primary") %>%
      group_by_(repr) %>%
      sample_frac(n/nrow(.)) %>%
      ungroup %>%
      mutate_at(vars(repr), as.factor)
    
  })
  
  # Display primaries
  output$prisamptab <- renderDataTable({
    
    validate(
      need(!is.null(input$drawsample), 'Select options and click Go')
    )
    
    prisamp()
  }, options = list(
    pageLength = 5,
    scrollX = TRUE
  ))
  
  # Display secondaries
  output$secsamptab <- renderDataTable({
    
    validate(
      need(!is.null(input$drawsample), 'Select options and click Go')
    )
    
    secsamp()
    
  }, options = list(
    pageLength = 5,
    scrollX = TRUE
  ))
  
  # Download primaries
  output$downloadPri <- downloadHandler(
    filename = function() {
      paste('Primary sample ', Sys.Date(), '.csv', sep='')
    },
    content = function(con) {
      write.csv(prisamp(), con)
    }
  )
  
  # Download Secondaries
  output$downloadSec <- downloadHandler(
    filename = function() {
      paste('Secondary sample ', Sys.Date(), '.csv', sep='')
    },
    content = function(con) {
      write.csv(secsamp(), con)
    }
  )
  
})

