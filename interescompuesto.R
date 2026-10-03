# interescompuesto.R
# Simulación educativa de interés compuesto con aportes mensuales.
# Alejandro Rodríguez (@Andalejo1109)
#
# Tesis que ilustra (no es asesoría):
#   Para ver ganancias hace falta tiempo y seguir aportando a capital.
#   No se pasa de US$ 200 o US$ 1.000 a cifras grandes de la noche a la mañana.
#
# Fórmula (anualidad ordinaria, aporte al cierre de cada mes):
#   r = tasa_anual / 12
#   n = años * 12
#   VF = P * (1 + r)^n + PMT * (((1 + r)^n - 1) / r)
#   Si PMT = 0, queda solo el capital inicial capitalizado.

# ===================== CONFIG (edita aquí) =====================
inicial        <- 1000          # USD al inicio
aporte_mensual <- 200           # USD al final de cada mes
anios          <- 15            # horizonte
tasas_anuales  <- c(0.10, 0.18, 0.23)
tasa_contraste <- 0.18          # misma tasa media, SIN más aportes
# ===============================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(gganimate)
})

# Carpeta de salida junto al script, no según el directorio desde donde se llame.
args_cmd <- commandArgs(trailingOnly = FALSE)
archivo <- sub("^--file=", "", grep("^--file=", args_cmd, value = TRUE))
script_dir <- if (length(archivo)) dirname(normalizePath(archivo)) else getwd()
dir_salida <- file.path(script_dir, "salida")
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# Camino mes a mes. El mes 0 es el capital inicial, antes del primer aporte.
simular <- function(p0, pmt, tasa_anual, n_meses) {
  r <- tasa_anual / 12
  valor <- numeric(n_meses + 1)
  aportado <- numeric(n_meses + 1)
  valor[1] <- p0
  aportado[1] <- p0
  for (m in seq_len(n_meses)) {
    valor[m + 1] <- valor[m] * (1 + r) + pmt
    aportado[m + 1] <- p0 + pmt * m
  }
  data.frame(
    mes = 0:n_meses,
    anio = (0:n_meses) / 12,
    valor = valor,
    aportado = aportado,
    ganancia = valor - aportado,
    stringsAsFactors = FALSE
  )
}

meses <- anios * 12
trozos <- list()

for (tasa in tasas_anuales) {
  d <- simular(inicial, aporte_mensual, tasa, meses)
  d$serie <- sprintf("%d%% con aportes", as.integer(round(tasa * 100)))
  d$tasa_anual <- tasa
  d$con_aportes <- TRUE
  trozos[[length(trozos) + 1]] <- d
}

sola <- simular(inicial, 0, tasa_contraste, meses)
nombre_sola <- sprintf("%d%% solo el inicial", as.integer(round(tasa_contraste * 100)))
sola$serie <- nombre_sola
sola$tasa_anual <- tasa_contraste
sola$con_aportes <- FALSE
trozos[[length(trozos) + 1]] <- sola

tray <- do.call(rbind, trozos)
rownames(tray) <- NULL

nombres_aportes <- sprintf("%d%% con aportes", as.integer(round(tasas_anuales * 100)))
orden <- c(nombres_aportes, nombre_sola)
tray$serie <- factor(tray$serie, levels = orden)

term <- tray[tray$mes == meses, c(
  "serie", "tasa_anual", "con_aportes", "aportado", "valor", "ganancia"
)]
term$ganancia_sobre_aportado <- term$ganancia / term$aportado
names(term) <- c(
  "escenario", "tasa_anual", "con_aportes",
  "capital_aportado_usd", "valor_final_usd", "ganancia_usd",
  "ganancia_sobre_aportado"
)
term$capital_aportado_usd <- round(term$capital_aportado_usd, 2)
term$valor_final_usd <- round(term$valor_final_usd, 2)
term$ganancia_usd <- round(term$ganancia_usd, 2)
term$ganancia_sobre_aportado <- round(term$ganancia_sobre_aportado, 6)

csv_path <- file.path(dir_salida, "valores_finales.csv")
write.csv(term, csv_path, row.names = FALSE, fileEncoding = "UTF-8")

cat("\nValores al cabo de", anios, "años (USD)\n")
print(term, row.names = FALSE, digits = 8)
cat("\n")

# Colores distintos por tasa. La línea sin aportes va en granate punteado.
paleta_base <- c("#1D4E89", "#C47B2B", "#1B7F6E", "#0E7C66", "#3D5A40")
pal <- setNames(paleta_base[seq_along(nombres_aportes)], nombres_aportes)
pal[[nombre_sola]] <- "#8C3A3A"
tipos <- setNames(rep("solid", length(nombres_aportes)), nombres_aportes)
tipos[[nombre_sola]] <- "22"

fmt_miles <- function(x) {
  format(round(x), big.mark = ".", decimal.mark = ",", scientific = FALSE, trim = TRUE)
}

finales <- tray[tray$mes == meses, ]
finales$etiqueta <- paste0("US$ ", fmt_miles(finales$valor))
# Etiquetas hacia la izquierda del punto final, para que no las corte el margen.
# vjust distinto evita que se monten sobre la línea.
finales$vjust <- ifelse(
  !finales$con_aportes, -1.15,
  ifelse(finales$tasa_anual >= 0.20, -0.55, ifelse(finales$tasa_anual >= 0.15, -0.35, 1.35))
)

fondo <- "#FBF6EF"
tinta <- "#2C2416"

subtitulo <- sprintf(
  paste0(
    "Inicio US$ %s  ·  aporte US$ %s al cierre de cada mes  ·  %d años\n",
    "Capitalización mensual (r = tasa anual / 12). ",
    "Línea punteada: el mismo inicio al %d%%, sin volver a aportar."
  ),
  fmt_miles(inicial),
  fmt_miles(aporte_mensual),
  anios,
  as.integer(round(tasa_contraste * 100))
)

base <- ggplot(tray, aes(x = anio, y = valor, color = serie, group = serie)) +
  geom_line(aes(linetype = serie), linewidth = 1.15) +
  scale_color_manual(values = pal, breaks = orden, name = NULL) +
  scale_linetype_manual(values = tipos, breaks = orden, name = NULL) +
  scale_x_continuous(
    breaks = seq(0, anios, by = 3),
    limits = c(0, anios),
    expand = expansion(mult = c(0.01, 0.04))
  ) +
  scale_y_continuous(
    labels = fmt_miles,
    expand = expansion(mult = c(0.02, 0.14))
  ) +
  labs(
    title = "Tiempo y aportes: así crece el interés compuesto",
    subtitle = subtitulo,
    x = "Años",
    y = "Valor del portafolio (USD)",
    caption = paste(
      "Simulación educativa. No es asesoría, ni promesa, ni un resultado de mercado.",
      "Una tasa fija solo sirve para ver la tesis: hace falta tiempo, seguir aportando y que el camino acompañe.",
      "@Andalejo1109",
      sep = "\n"
    )
  ) +
  theme_minimal(base_size = 13, base_family = "DejaVu Sans") +
  theme(
    plot.background = element_rect(fill = fondo, color = NA),
    panel.background = element_rect(fill = fondo, color = NA),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "#E7DCC8", linewidth = 0.35),
    plot.title = element_text(face = "bold", colour = tinta, size = 17, margin = margin(b = 6)),
    plot.subtitle = element_text(colour = "#5C5144", size = 11, lineheight = 1.15),
    plot.caption = element_text(colour = "#7A6E5F", hjust = 0, size = 9, lineheight = 1.05),
    axis.title = element_text(colour = tinta),
    axis.text = element_text(colour = "#4A4036"),
    legend.position = "top",
    legend.text = element_text(colour = tinta, size = 11),
    plot.margin = margin(14, 18, 10, 12)
  )

estatico <- base +
  geom_point(data = finales, size = 2.4, show.legend = FALSE) +
  geom_text(
    data = finales,
    aes(label = etiqueta, vjust = vjust),
    hjust = 1.06,
    size = 3.5,
    fontface = "bold",
    show.legend = FALSE,
    family = "DejaVu Sans"
  )

png_path <- file.path(dir_salida, "trayectoria.png")
ggsave(png_path, estatico, width = 11.2, height = 7.1, dpi = 150, bg = fondo, device = grDevices::png)

# GIF: las líneas se revelan mes a mes. Lienzo amplio para que título y ejes no se pisen.
# Sin etiquetas finales, para no anticipar el desenlace.
animado <- base +
  transition_reveal(mes) +
  labs(
    title = "Tiempo y aportes: el camino no es de la noche a la mañana",
    subtitle = sprintf(
      "Inicio US$ %s  ·  US$ %s al mes  ·  %d años  ·  punteada: solo el inicial al %d%%",
      fmt_miles(inicial),
      fmt_miles(aporte_mensual),
      anios,
      as.integer(round(tasa_contraste * 100))
    ),
    caption = "Simulación educativa. No es asesoría ni promesa de rentabilidad.  @Andalejo1109"
  ) +
  theme(
    plot.title = element_text(size = 16, margin = margin(b = 6)),
    plot.subtitle = element_text(size = 11, margin = margin(b = 8)),
    plot.caption = element_text(size = 9, margin = margin(t = 12)),
    axis.title.x = element_text(margin = margin(t = 8)),
    plot.margin = margin(16, 20, 16, 14)
  )

gif_path <- file.path(dir_salida, "trayectoria.gif")
anim <- animate(
  animado,
  nframes = 90,
  fps = 10,
  width = 1320,
  height = 840,
  res = 120,
  renderer = magick_renderer(loop = TRUE),
  bg = fondo,
  device = "png"
)
anim_save(gif_path, animation = anim)

cat("PNG:", png_path, "\n")
cat("GIF:", gif_path, "\n")
cat("CSV:", csv_path, "\n")
