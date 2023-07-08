library(ggplot2)

grid_size <- 50
empty_ratio <- 0.33
threshold <- 0.70
n_frames <- 80

initialize_grid <- function() {
  grid <- matrix(sample(c(0, 1, 2), grid_size * grid_size, replace = TRUE, prob = c(empty_ratio, (1 - empty_ratio) / 2, (1 - empty_ratio) / 2)), nrow = grid_size)
  return(grid)
}

count_similar <- function(grid, x, y) {
  race <- grid[x, y]
  similar <- 0
  total <- 0
  for (dx in -1:1) {
    for (dy in -1:1) {
      nx <- x + dx
      ny <- y + dy
      if (nx >= 1 && nx <= grid_size && ny >= 1 && ny <= grid_size && !(dx == 0 && dy == 0) && grid[nx, ny] != 0) {
        total <- total + 1
        similar <- similar + (grid[nx, ny] == race)
      }
    }
  }
  if (total == 0) return(TRUE)
  return(similar / total >= threshold)
}

update_grid <- function(grid) {
  unsatisfied <- c()
  for (x in 1:grid_size) {
    for (y in 1:grid_size) {
      if (grid[x, y] != 0 && !count_similar(grid, x, y)) {
        unsatisfied <- rbind(unsatisfied, c(x, y))
      }
    }
  }

  empties <- which(grid == 0, arr.ind=TRUE)
  if (length(unsatisfied) > 0) {
    for (i in 1:nrow(unsatisfied)) {
      if (nrow(empties) > 0) {
        index <- sample(1:nrow(empties), 1)
        grid[empties[index,1], empties[index,2]] <- grid[unsatisfied[i,1], unsatisfied[i,2]]
        grid[unsatisfied[i,1], unsatisfied[i,2]] <- 0
        empties <- rbind(empties[-index,], unsatisfied[i, ])
      }
    }
  }
  return(grid)
}

plot_grid <- function(grid, frame) {
  df <- data.frame(expand.grid(x = 1:grid_size, y = 1:grid_size), race = as.factor(c(grid)))
  p <- ggplot(df, aes(x = x, y = y, fill = race)) +
    geom_tile() +
    scale_fill_manual(values = c("white", "#54a0ff", "#ff9f43"),
      labels = c("Empty", "Race 1", "Race 2")) +
    theme_void() +
    theme(legend.position = "right", plot.caption.position = 'plot', plot.caption = element_text(hjust = .5)) +
    labs(fill = "") +
    coord_equal() + 
    ggtitle("Shelling's Model of Segregation",
    "Tolerance Threshold: .70") + 
    labs(caption = stringr::str_wrap('Agents move to random empty spots if less than 70% of their neighbors are of the same race, leading to segregation.', 60))
  
  ggsave(sprintf("frame%03d.png", frame), p, width=500, height=300, unit='px', scale=3)
}

run_simulation <- function() {
  grid <- initialize_grid()
  for (frame in 1:n_frames) {
    grid <- update_grid(grid)
    plot_grid(grid, frame)
  }
  # use ffmpeg and ImageMagick to create an mp4 
  system("convert -delay 20 -loop 0 -background white -alpha remove -alpha off *.png shelling_model.mp4")

  # also create a GIF 
  system("convert -delay 20 -loop 0 -background white -alpha remove -alpha off -layers Optimize *.png shelling_model.gif")
}

# Run the simulation
run_simulation()

