stack_alpha_color <- function(
  base,
  alpha = 0.1,
  k = 1,
  names = c("1"),
  bg = "#FFFFFF"
) {
  C <- drop(col2rgb(base)) / 255
  B <- drop(col2rgb(bg)) / 255
  w <- 1 - (1 - alpha)^k
  out <- vapply(
    w,
    function(W) {
      col <- B * (1 - W) + C * W
      rgb(col[1], col[2], col[3])
    },
    character(1)
  )
  names(out) <- names
  out
}

ribbon_pal <- stack_alpha_color(
  "blue",
  0.1,
  k = 5:1,
  names = c("0.5", "0.75", "0.9", "0.95", "0.99")
)
