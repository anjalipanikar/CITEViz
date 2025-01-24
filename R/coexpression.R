#' Bilinear Interpolation
#'
#' Takes in a given x and y coordinate, the dimension of a square grid, and four values representing the base red, green, or blue (RGB) color values (0-255) of the four quadrants of the square grid
#' Returns the bilinear interpolated red, green, or blue value (0-255) of the given input coordinates (x,y)
#'
#' @param x integer vector
#' @param y integer vector
#' @param ngrid integer taken from get_color_matrix_df
#' @param quad11 integer
#' @param quad21 integer
#' @param quad12 integer
#' @param quad22 integer
#'
#' @return numeric vector for color values used in coexpression plot
#' @export
#'
#' @examples
#' ngrid <- 16
#' color_matrix_df <- expand.grid(x_value = 0:ngrid, y_value = 0:ngrid)
#' color10 <- c(255,0,0) # numeric vector of RGB values for red quadrant of 2d color matrix
#' color01 <- c(0,0,255) # numeric vector of RGB values for blue quadrant of 2d color matrix
#' color00 <- c(217,217,217) # numeric vector of RGB values for light gray quadrant of 2d color matrix
#' color11 <- c(255,0,255) # numeric vector of RGB values for pink/violet quadrant of 2d color matrix
#' color_matrix_df$red_values <- get_bilinear_val(color_matrix_df$x_value, color_matrix_df$y_value, ngrid, color00[1], color10[1], color01[1], color11[1])
#' color_matrix_df$green_values <- get_bilinear_val(color_matrix_df$x_value, color_matrix_df$y_value, ngrid, color00[2], color10[2], color01[2], color11[2])
#' color_matrix_df$blue_values <- get_bilinear_val(color_matrix_df$x_value, color_matrix_df$y_value, ngrid, color00[3], color10[3], color01[3], color11[3])
get_bilinear_val <- function(x,y,ngrid,quad11,quad21,quad12,quad22){
  temp_val <- quad11*(ngrid-x)*(ngrid-y) + quad21*x*(ngrid-y) + quad12*(ngrid-x)*y + quad22*x*y
  bilinear_val <- temp_val / (ngrid*ngrid)
  return(bilinear_val)
}


#' Create 2D color dataframe for gene/ADT coexpression
#'
#' @param ngrid integer setting the resolution (dimensions) of color grid (e.g., ngrid = 16 sets a 16x16 color grid). Default is ngrid=16.
#'
#' @importFrom grDevices rgb
#'
#' @return dataframe for use in coexpression legend
#' @export
#'
#' @examples
#' get_color_matrix_df(10)
get_color_matrix_df <- function(ngrid = 16) {
  color_matrix_df <- expand.grid(x_value = 0:ngrid, y_value = 0:ngrid)
  color10 <- c(255,0,0) # numeric vector of RGB values for red quadrant of 2d color matrix
  color01 <- c(0,0,255) # numeric vector of RGB values for blue quadrant of 2d color matrix
  color00 <- c(217,217,217) # numeric vector of RGB values for light gray quadrant of 2d color matrix
  color11 <- c(255,0,255) # numeric vector of RGB values for pink/violet quadrant of 2d color matrix
  color_matrix_df$R <- get_bilinear_val(color_matrix_df$x_value, color_matrix_df$y_value, ngrid, color00[1], color10[1], color01[1], color11[1])
  color_matrix_df$G <- get_bilinear_val(color_matrix_df$x_value, color_matrix_df$y_value, ngrid, color00[2], color10[2], color01[2], color11[2])
  color_matrix_df$B <- get_bilinear_val(color_matrix_df$x_value, color_matrix_df$y_value, ngrid, color00[3], color10[3], color01[3], color11[3])
  color_matrix_df$hex_color_mix <- rgb(color_matrix_df$R, color_matrix_df$G, color_matrix_df$B, maxColorValue = 255)
  
  return(color_matrix_df)
}


#' Create 2D color legend plot for gene/ADT coexpression
#'
#' @param input Shiny internal parameter object containing UI user input values
#' @param myso a Seurat object
#'
#'
#' @import magrittr
#' @importFrom ggplot2 aes ggplot geom_tile labs scale_x_continuous scale_y_continuous
#' 
#' @return legend for app coexpression plot
#' @export
#'
#' @examples 
#' \dontrun{
#' seurat_object <- readRDS("path/to/RDSfile/containing/Seurat/object")
#' create_2d_color_legend(input, seurat_object)
#' }
create_2d_color_legend <- function(input, myso) {
  #require these UI input items to render before trying to get data from them for plotting, so that errors don't get thrown
  shiny::req(input$rds_input_file, input$Assay_x_axis, input$Assay_y_axis, input$x_axis_feature, input$y_axis_feature)
  
  #selected metadata to color clusters by
  color_x <- input$x_axis_feature
  color_y <- input$y_axis_feature
  
  SeuratObject::DefaultAssay(myso) <- input$Assay_x_axis
  count_data_x <- SeuratObject::FetchData(object = myso, vars = color_x, slot = "data")
  # extract only the count values as a vector from the original count data dataframe
  count_data_x <- count_data_x[[color_x]]
  
  SeuratObject::DefaultAssay(myso) <- input$Assay_y_axis
  count_data_y <- SeuratObject::FetchData(object = myso, vars = color_y, slot = "data")
  # extract only the count values as a vector from the original count data dataframe
  count_data_y <- count_data_y[[color_y]]
  
  ngrid <- 16
  color_matrix_df <- get_color_matrix_df(ngrid)
  
  #show plot of 2D color legend
  color_matrix_df %>%
    ggplot2::ggplot(aes(x = x_value, y = y_value)) + 
    ggplot2::geom_tile(fill = color_matrix_df$hex_color_mix) +
    ggplot2::labs(x = input$x_axis_feature, y = input$y_axis_feature) +
    ggplot2::scale_x_continuous(breaks = c(0, ngrid), 
                                labels = c(paste0("low\n", round(min(count_data_x), digits=2)), 
                                           paste0("high\n", round(max(count_data_x), digits=2)))) + 
    ggplot2::scale_y_continuous(breaks = c(0, ngrid), 
                                labels = c(paste0("low\n", round(min(count_data_y), digits=2)), 
                                           paste0("high\n", round(max(count_data_y), digits=2)))) 
}
