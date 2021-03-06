# Tutorials
#https://hilaryparker.com/2014/04/29/writing-an-r-package-from-scratch/
#http://r-pkgs.had.co.nz/description.html
#https://cran.r-project.org/web/packages/roxygen2/vignettes/rd.html

## Packages to install
#install.packages("devtools")
#install.packages("digest")
#devtools::install_github("klutometis/roxygen")

## Packages to load
#library("devtools")
#library("roxygen2")

## Creating package
#packageDirectory <- "/home/josephcrispell/Desktop/Research/addTextLabels/"
#create(packageDirectory)
#setwd(packageDirectory)

## Documenting changes
#setwd(packageDirectory)
#document()

## Install
#setwd("..")
#install("addTextLabels")

#' Add non-overlapping text labels to plot
#'
#' This function is similar to the \code{text()} function but it will attempt to re-locate labels that will overlap
#' @param xCoords A vector containing the X coordinates for labels
#' @param yCoords A vector containing the Y coordinates for labels
#' @param labels A vector containing the labels to be plotted
#' @param cex A number to scale the size of the plotted labels. Defaults to 1
#' @param col.label The colour of the plotted labels. Defaults to "red"
#' @param col.line The colour of the line to plot from relocated labels to original location. Defaults to "black"
#' @param col.background An optional colour for a background polygon plotted behind labels. Defaults to NULL - won't be plotted
#' @param lty A number detailing the type of line to plot from relocated labels to original location. 0: blank, 1: solid, 2: dashed, 3: dotted, 4: dotdash, 5: longdash, and 6: twodash. Defaults to 1
#' @param lwd A number to scale the size of line from relocated labels to original location. Defaults to 1
#' @param border The colour of the border to be plotted around the polygon. Defaults to NA - won't be plotted
#' @param avoidPoints A logical variable indicating whether labels shouldn't be plotted on top of points
#' @keywords text label plot
#' @export
#' @examples 
#' # Create some random points
#' n <- 50
#' coords <- data.frame(X=runif(n), Y=runif(n), Name="Test Label")
#' 
#' # Plot them without labels
#' plot(x=coords$X, y=coords$Y, pch=19, bty="n", xaxt="n", yaxt="n", col="red", xlab="X", ylab="Y")
#' 
#' # With potentially overlapping labels
#' plot(x=coords$X, y=coords$Y, pch=19, bty="n", xaxt="n", yaxt="n", col="red", xlab="X", ylab="Y")
#' text(coords$X, coords$Y, labels=coords$Name, xpd=TRUE)
#' 
#' # Plot them with non-overlapping labels
#' plot(x=coords$X, y=coords$Y, pch=19, bty="n", xaxt="n", yaxt="n", col="red", xlab="X", ylab="Y")
#' addTextLabels(coords$X, coords$Y, coords$Name, cex=1, col.label="black")
#' 
#' # Plot them with non-overlapping labels
#' plot(x=coords$X, y=coords$Y, pch=19, bty="n", xaxt="n", yaxt="n", col="red", xlab="X", ylab="Y")
#' addTextLabels(coords$X, coords$Y, coords$Name, cex=1, col.background=rgb(0,0,0, 0.75), col.label="white")
addTextLabels <- function(xCoords, yCoords, labels, cex=1, col.label="red", col.line="black", col.background=NULL,
                          lty=1, lwd=1, border=NA, avoidPoints=TRUE){
  
  ###############################
  # Store the point information #
  ###############################
  
  # Store the input coordinates and labels
  pointInfo <- list("X"=xCoords, "Y"=yCoords, "Labels"=labels, "N"=length(xCoords))

  # Set the amount to pad onto height and width
  heightPad <- 0.5
  widthPad <- 0.02
  if(is.null(col.background)){
    heightPad <- 0
    widthPad <- 0
  }
  
  # Calculate the label heights and widths
  pointInfo <- calculateLabelHeightsAndWidths(pointInfo=pointInfo, cex=cex,
                                              heightPad=heightPad, widthPad=widthPad)
    
  ###########################################
  # Produce a list of alternative locations #
  ###########################################
  
  # Generate the alternative locations
  alternativeLocations <- generateAlternativeLocations()

  # Calculate the distance between the actual and alternative points - rescale X axis remove axis range bias
  distances <- euclideanDistancesWithRescaledXAxis(pointInfo, alternativeLocations)
  
  ###############################################################
  # Create a list to store the information about plotted points #
  ###############################################################
  
  # Initialise the list to store the information about plotted labels
  plottedLabelInfo <- list("X"=c(), "Y"=c(), "Height"=c(), "Width"=c(), "N"=0)
  
  ##############################################################
  # Add labels to plot assigning new locations where necessary #
  ##############################################################
  
  # Plot the point label
  for(i in seq_len(pointInfo$N)){

    # Get the information for the current point
    x <- pointInfo$X[i]
    y <- pointInfo$Y[i]
    label <- pointInfo$Labels[i]
    height <- pointInfo$Heights[i]
    width <- pointInfo$Widths[i]
    
    # Is the current point too close to others?
    if(alternativeLocations$N != 0 && (avoidPoints == TRUE || tooClose(x, y, height, width, plottedLabelInfo))){

      # Get a new location
      newLocationIndex <- chooseNewLocation(pointInfo, i, alternativeLocations, distances, plottedLabelInfo)

      # Get the coordinates for the chosen alternate location
      altX <- alternativeLocations$X[newLocationIndex]
      altY <- alternativeLocations$Y[newLocationIndex]
      
      # Add line back to previous location
      addLineBackToOriginalLocation(altX=altX, altY=altY, x=x, y=y, label=label,
                                    cex=cex, col=col.line, lty=lty, lwd=lwd, heightPad=heightPad, widthPad=widthPad)
      
      # Add label
      addLabel(x=altX, y=altY, label=label,
               cex=cex, col=col.label, bg=col.background, border=border, heightPad=heightPad, widthPad=widthPad)
        
      # Append the plotted label information
      plottedLabelInfo <- addPlottedLabel(x=altX, y=altY, height=height, width=width,
                                          plottedLabelInfo=plottedLabelInfo)
        
    }else{
      
      # Add label
      addLabel(x=x, y=y, label=label,
               cex=cex, col=col.label, bg=col.background, border=border,
               heightPad=heightPad, widthPad=widthPad)
      
      # Append the plotted label information
      plottedLabelInfo <- addPlottedLabel(x=x, y=y, height=height, width=width,
                                          plottedLabelInfo=plottedLabelInfo)
    }
  }
}

#' Add the information associated with a text label that has been plotted
#'
#' Function used by \code{addTextLabels()}
#' @param x X coordinate of point of interest
#' @param y Y coodrinate of point of interest
#' @param height The height of the label associated with the point of interest
#' @param width The width of the label associated with the point of interest
#' @param plottedLabelInfo The coordinates and label information about the locations where a label has already plotted
#' @keywords internal
#' @return Returns a list containing information for all the plotted labels, included the one just added
addPlottedLabel <- function(x, y, height, width, plottedLabelInfo){
  
  plottedLabelInfo$X[plottedLabelInfo$N + 1] <- x
  plottedLabelInfo$Y[plottedLabelInfo$N + 1] <- y
  plottedLabelInfo$Heights[plottedLabelInfo$N + 1] <- height
  plottedLabelInfo$Widths[plottedLabelInfo$N + 1] <- width
  
  plottedLabelInfo$N <- plottedLabelInfo$N + 1
  
  return(plottedLabelInfo)
}

#' Plot line from new alternative location back to original
#'
#' Function used by \code{addTextLabels()}
#' @param altX The X coordinate of new location
#' @param altY The Y coordinate of new location
#' @param x The X coordinate of original location
#' @param y The Y coordinate of original location
#' @param label The label to be plotted. Required to work out when line ends
#' @param cex The number used to scale the size of the label. Required to work out when line ends
#' @param col Colour of line to be plotted
#' @param lty A number detailing the type of line to be plotted. 0: blank, 1: solid, 2: dashed, 3: dotted, 4: dotdash, 5: longdash, and 6: twodash.
#' @param lwd A number to scale the size of plotted line.
#' @param heightPad Multiplyer for label height should added to label to be used to pad height
#' @param widthPad Multiplyer for label width should added to label to be used to pad width
#' @keywords internal
addLineBackToOriginalLocation <- function(altX, altY, x, y, label, cex, col, lty, lwd, heightPad, widthPad){
  
  # Calculate the label width and height
  labelHeight <- strheight(label, cex=cex)
  labelWidth <- strwidth(label, cex=cex)
  
  # Calculate amount outer left/right and above/below
  xHalf <- labelWidth * (0.5 + (0.5 * widthPad))
  yHalf <- labelHeight * (0.5 + (0.5 * heightPad))
  
  # Create a set of points marking the boundaries of the label
  xMarkers <- c(seq(from=altX - xHalf, to=altX + xHalf, by=0.05*labelWidth), altX + xHalf)
  yMarkers <- c(seq(from=altY - yHalf, to=altY + yHalf, by=0.05*labelHeight), altY + yHalf)
  
  # Calculate the closest pair of X and Y coordinates to the origin
  closestX <- xMarkers[which.min(abs(xMarkers - x))]
  closestY <- yMarkers[which.min(abs(yMarkers - y))]
  
  # Plot the line
  points(x=c(closestX, x), y=c(closestY, y), type="l", col=col, lty=lty, lwd=lwd)
}

#' Calculate the heights and widths of the labels in the current plotting window
#'
#' Function used by \code{addTextLabels()}
#' @param pointInfo A list storing the coordinates and labels of input points
#' @param cex The number used to scale the size of the label and therefore its height and width
#' @param heightPad Multiplyer for label height should added to label to be used to pad height
#' @param widthPad Multiplyer for label width should added to label to be used to pad width
#' @keywords internal
#' @return Returns a list storing the coordinates, labels, and the heights and widths of the labels, for input points
calculateLabelHeightsAndWidths <- function(pointInfo, cex, heightPad, widthPad){
  
  # Get the text label heights and lengths
  textHeights <- strheight(pointInfo$Labels) * cex
  textWidths <- strwidth(pointInfo$Labels) * cex
  
  # Add padding to widths and heights
  # Note multiplies padding by 2 - stops background polygons being directly adjacent
  pointInfo[["Heights"]] <- textHeights + (2 * heightPad * textHeights)
  pointInfo[["Widths"]] <- textWidths + (2 * widthPad * textWidths)

  return(pointInfo)
}

#' Generate a set of alternative locations where labels can be plotted if they overlap with another label
#'
#' Function used by \code{addTextLabels()}
#' @keywords internal
#' @return Returns a list containing the coordinates of the alternative locations
generateAlternativeLocations <- function(){
  
  # Initialise a list to store the alternative locations
  alternativeLocations <- list("X"=c(), "Y"=c())
  
  # Get the axis limits
  axisLimits <- par("usr")
  
  # Define the spacer for each axis
  spacerX <- 0.01 * (axisLimits[2] - axisLimits[1])
  spacerY <- 0.01 * (axisLimits[4] - axisLimits[3])
  
  # Generate the set of points based upon the spacer
  for(i in seq(axisLimits[1], axisLimits[2], spacerX)){
    for(j in seq(axisLimits[3], axisLimits[4], spacerY)){
      
      alternativeLocations$X[length(alternativeLocations$X) + 1] <- i
      alternativeLocations$Y[length(alternativeLocations$Y) + 1] <- j
    }
  }
  # points(alternativeLocations$X, alternativeLocations$Y, col=rgb(0,0,0, 0.5), pch=20, xpd=TRUE)

  # Note the number of alternative locations created
  alternativeLocations[["N"]] <- length(alternativeLocations$X)
  
  return(alternativeLocations)
}

#' Plot a label with optional polygon background
#'
#' Function used by \code{addTextLabels()}
#' @param x The X coordinate at which label is to be plotted
#' @param y The Y coordinate at which label is to be plotted
#' @param label The label to be plotted
#' @param cex The number used to scale the size of the label
#' @param col The colour of the label to be plotted
#' @param bg The colour of the polygon to be plotted. If NULL no polygon plotted
#' @param border The colour of the polygon border. If NA, no border plotted
#' @param heightPad Multiplyer for label height should added to label to be used to pad height
#' @param widthPad Multiplyer for label width should added to label to be used to pad width
#' @keywords internal
addLabel <- function(x, y, label, cex, col, bg, border, heightPad, widthPad){
  
  # Add a background polygon - if requested
  if(is.null(bg) == FALSE){
    
    # Calculate the height and width of the label
    labelHeight <- strheight(label, cex=cex)
    labelWidth <- strwidth(label, cex=cex)
    
    # Calculate amount outer left/right and above/below
    xHalf <- labelWidth * (0.5 + (0.5 * widthPad))
    yHalf <- labelHeight * (0.5 + (0.5 * heightPad))
    
    # Plot the background polygon
    polygon(x=c(x - xHalf, x - xHalf, x + xHalf, x + xHalf),
            y=c(y - yHalf, y + yHalf, y + yHalf, y - yHalf), 
            col=bg, border=border, xpd=TRUE)
  }
  
  
  # Add label
  text(x=x, y=y, labels=label, xpd=TRUE, cex=cex, col=col)
}

#' Remove coordinates of alternative locations that are too close to coordinates
#'
#' Function used by \code{addTextLabels()}
#' @param altXs A vector of X coordinates for alternative locations
#' @param altYs A vector of Y coordinates for alternative locations
#' @param index The index of the point of interest in the coordinate vectors
#' @param textHeight The height of the label to be plotted at the point of interest
#' @param textWidth The width of the label to be plotted at the point of interest
#' @param distances The distances between the actual and alternative locations
#' @keywords internal
#' @return Returns a list of the coordinates of the alternative locations that weren't too close and the distance matrix of the alternate locations to the actual locations
removeLocationAndThoseCloseToItFromAlternatives <- function(altXs, altYs, index, textHeight, textWidth, distances){
  remove <- c(index)
  for(i in 1:length(altXs)){
    
    if(i == index){
      next
    }
    
    if(abs(altXs[index] - altXs[i]) < textWidth &&
       abs(altYs[index] - altYs[i]) < textHeight){
      remove[length(remove) + 1] <- i
    }
  }
  
  altXs <- altXs[-remove]
  altYs <- altYs[-remove]
  distances <- distances[, -remove]
  
  return(list("X" = altXs, "Y" = altYs, "distances"=distances))
}

#' A function to choose (from the alternative locations) a new location for a label to be plotted at
#'
#' Function used by \code{addTextLabels()}
#' @param pointInfo A list storing the information for the input points
#' @param index The index of the point of interest
#' @param alternativeLocations The coordinates of the alternative locations
#' @param distances The distances between the alternative locations and the input points
#' @param plottedLabelInfo The coordinates and label information about the locations where a label has already plotted
#' @keywords internal
#' @return Returns the index of the chosen alternative location
chooseNewLocation <- function(pointInfo, index, alternativeLocations, distances, plottedLabelInfo){
  
  # points(alternativeLocations$X, alternativeLocations$Y, pch=19, xpd=TRUE,
  #        col=rgb(1,0,0, distances[index, ] / max(distances[index, ])))
  
  # Get the information about the current point
  x <- pointInfo$X[index]
  y <- pointInfo$Y[index]
  height <- pointInfo$Heights[index]
  width <- pointInfo$Widths[index]
  
  # Get the indices of the alternative locations as an ordered
  orderedAlternateLocationIndices <- order(distances[index, ])

  # Initialise a variable to store the index of the selected alternative location
  indexOfSelectedAlternativeLocation <- -1
  
  # Examine each of the alternate locations in order
  for(i in orderedAlternateLocationIndices){
    
    # Store the current index
    indexOfSelectedAlternativeLocation <- i
    
    # Get the coordinates of the current alternative location
    altX <- alternativeLocations$X[i]
    altY <- alternativeLocations$Y[i]

    # Check current alternative location isn't too close to plotted labels or the plotted input points
    if(overlapsWithPlottedPoints(x=altX, y=altY, height=height, width=width, pointInfo=pointInfo) == FALSE &&
       tooClose(x=altX, y=altY, height=height, width=width, plottedLabelInfo) == FALSE){
      break
    }
  }
  
  return(indexOfSelectedAlternativeLocation)
}

#' Checks whether a point is too close to any of the plotted points
#'
#' Function used by \code{addTextLabels()}
#' @param x X coordinate of point of interest
#' @param y Y coodrinate of point of interest
#' @param height The height of the label associated with the point of interest
#' @param width The width of the label associated with the point of interest
#' @param pointInfo A list storing the information for the input points - that have been plotted
#' @keywords internal
#' @return Returns a logical variable to indicate whether the point of interest was too close to any plotted points
overlapsWithPlottedPoints <- function(x, y, height, width, pointInfo){
  
  result <- FALSE
  for(i in seq_len(pointInfo$N)){
    
    if(abs(x - pointInfo$X[i]) < width && abs(y - pointInfo$Y[i]) < height){
      result <- TRUE
      break
    }
  }
  
  return(result)
}

#' Checks whether a point is too close to any of the plotted labels
#'
#' Function used by \code{addTextLabels()}
#' @param x X coordinate of point of interest
#' @param y Y coodrinate of point of interest
#' @param height The height of the label associated with the point of interest
#' @param width The width of the label associated with the point of interest
#' @param plottedLabelInfo The coordinates and label information about the locations where a label has already plotted
#' @keywords internal
#' @return Returns a logical variable to indicate whether the point of interest was too close to any plotted labels
tooClose <- function(x, y, height, width, plottedLabelInfo){

  # Check if the current point is too close to any of the plotted locations
  result <- FALSE
  for(i in seq_len(plottedLabelInfo$N)){
    
    if(abs(x - plottedLabelInfo$X[i]) < (0.5 * plottedLabelInfo$Widths[i]) + (0.5 * width) &&
       abs(y - plottedLabelInfo$Y[i]) < (0.5 * plottedLabelInfo$Heights[i]) + (0.5 * height)){
      result <- TRUE
      break
    }
  }
  
  return(result) 
}

#' Calculate the euclidean distance between two sets of points. Note: Rescales X axis to match scale of Y
#'
#' Function used by \code{addTextLabels()}
#' @param pointInfo A list storing the information for the input points
#' @param alternativeLocations A list storing the coordinates of the alternative locations
#' @keywords internal
#' @return Returns the distances between the sets of points provided
euclideanDistancesWithRescaledXAxis <- function(pointInfo, alternativeLocations){
  
  # Get the axis limits
  axisLimits <- par("usr")
  
  # Calculate the axis ranges
  xRange = axisLimits[2] - axisLimits[1]
  yRange = axisLimits[4] - axisLimits[3]
  
  # Calculate the xFactor
  xFactor <- yRange / xRange
  
  # Initialise a matrix to store distances - note that it is non-symmetric!!!
  distances <- matrix(NA, nrow=pointInfo$N, ncol=alternativeLocations$N)
  
  # Fill the matrix with distances
  for(row in seq_len(nrow(distances))){
    
    for(col in seq_len(ncol(distances))){
      
      # Calculate the distance between the current pair of points
      # REMEMBER to correct the X values for the axes ranges
      distances[row, col] <- euclideanDistance(x1=pointInfo$X[row] * xFactor,
                                               y1=pointInfo$Y[row],
                                               x2=alternativeLocations$X[col] * xFactor,
                                               y2=alternativeLocations$Y[col])
    }
  }
  
  return(distances)
}

#' Calculate the euclidean distance between two points
#'
#' Function used by \code{addTextLabels()}
#' @param x1 The X coordinate of the first point
#' @param y1 The Y coordinate of the first point
#' @param x2 The X coordinate of the second point
#' @param y2 The Y coordinate of the second point
#' @keywords internal
#' @return Returns the distance between the points provided
euclideanDistance <- function(x1, y1, x2, y2){
  return(sqrt((x1 - x2)^2 + (y1 - y2)^2))
}