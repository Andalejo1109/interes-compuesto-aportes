# apendice_tres_aportes.R
# Apéndice de interescompuesto.R. El script original no se toca.
# Alejandro Rodríguez (@Andalejo1109)
#
# Tesis que ilustra (no es asesoría ni un plan de pensión):
#   Con la misma tasa, el tiempo que a uno le queda cambia el aporte.
#   Quien está cerca de pensionarse tiene que poner mucho más cada mes.
#   Quien puede esperar construye con un aporte más chico, pero no se salta los años.
#
# Fórmula (anualidad ordinaria, aporte al cierre de cada mes, P = 0):
#   r = tasa_anual / 12
#   n = años * 12
#   VF = PMT * (((1 + r)^n - 1) / r)
#   Capital aportado = PMT * n
#   Ganancia = VF - capital aportado

# ===================== CONFIG (edita aquí) =====================
inicial       <- 0              # USD al inicio. Cero: todo sale de los aportes.
aportes       <- c(500, 2000, 4000)
tasa_anual    <- 0.15           # la misma para los tres
anios         <- 15
cortes_anios  <- c(4, 5, 10, 15)  # el año 4 es la marca de pensión del de US$ 4.000
# ===============================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(gganimate)
})

args_cmd <- commandArgs(trailingOnly = FALSE)
archivo <- sub("^--file=", "", grep("^--file=", args_cmd, value = TRUE))
script_dir <- if (length(archivo)) dirname(normalizePath(archivo)) else getwd()
dir_salida <- file.path(script_dir, "salida")
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# Horizonte narrativo, no un consejo.
horizonte_de <- function(pmt) {
  if (pmt >= 4000) {
    "Unos 4 años para la pensión"
  } else if (pmt >= 2000) {
    "Horizonte de 10 a 15 años"
  } else {
    "Puede esperar 15 años o más"
  }
}

simular <- function(p0, pmt, tasa, n_meses) {
  r <- tasa / 12
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

# VF cerrado de la anualidad ordinaria, para contrastar el recorrido mes a mes.
vf_cerrado <- function(p0, pmt, tasa, n_meses) {
  r <- tasa / 12
  p0 * (1 + r)^n_meses + pmt * (((1 + r)^n_meses - 1) / r)
}

meses <- anios * 12
trozos <- lapply(aportes, function(pmt) {
  d <- simular(inicial, pmt, tasa_anual, meses)
  d$aporte_mensual <- pmt
  d$serie <- sprintf(
    "US$ %s / mes",
    format(pmt, big.mark = ".", decimal.mark = ",", scientific = FALSE, trim = TRUE)
  )
  d$horizonte <- horizonte_de(pmt)
  d
})

tray <- do.call(rbind, trozos)
rownames(tray) <- NULL

orden <- sprintf(
  "US$ %s / mes",
  format(sort(aportes, decreasing = TRUE), big.mark = ".", decimal.mark = ",", scientific = FALSE, trim = TRUE)
)
tray$serie <- factor(tray$serie, levels = orden)

# Cortes: año 4 (pensión del aporte alto) y 5, 10, 15 para los tres.
cortes <- tray[tray$anio %in% cortes_anios, c(
  "serie", "aporte_mensual", "horizonte", "anio", "mes",
  "aportado", "valor", "ganancia"
)]
cortes <- cortes[order(-cortes$aporte_mensual, cortes$anio), ]
rownames(cortes) <- NULL

cerrado <- mapply(
  vf_cerrado,
  inicial,
  cortes$aporte_mensual,
  tasa_anual,
  cortes$mes
)
cortes$valor_formula <- as.numeric(cerrado)
cortes$dif_vs_formula <- cortes$valor - cortes$valor_formula

cat("\nMáxima diferencia simulación vs fórmula cerrada:",
    format(max(abs(cortes$dif_vs_formula)), scientific = TRUE), "USD\n")

out <- data.frame(
  escenario = cortes$serie,
  aporte_mensual_usd = cortes$aporte_mensual,
  horizonte = cortes$horizonte,
  anio = cortes$anio,
  meses = cortes$mes,
  tasa_anual = tasa_anual,
  capital_inicial_usd = inicial,
  capital_aportado_usd = round(cortes$aportado, 2),
  valor_usd = round(cortes$valor, 2),
  ganancia_usd = round(cortes$ganancia, 2),
  stringsAsFactors = FALSE
)

csv_path <- file.path(dir_salida, "apendice_cortes.csv")
write.csv(out, csv_path, row.names = FALSE, fileEncoding = "UTF-8")

cat("\nCortes (USD). Tasa", tasa_anual, "capitalizada cada mes. Inicial", inicial, "\n")
print(out, row.names = FALSE, digits = 10)
cat("\n")

fmt_miles <- function(x) {
  format(round(x), big.mark = ".", decimal.mark = ",", scientific = FALSE, trim = TRUE)
}

pal <- setNames(
  c("#1D4E89", "#C47B2B", "#1B7F6E"),
  orden
)

fondo <- "#FBF6EF"
tinta <- "#2C2416"

etiquetas_serie <- setNames(
  c(
    "US$ 4.000/mes · unos 4 años para la pensión",
    "US$ 2.000/mes · horizonte de 10 a 15 años",
    "US$ 500/mes · puede esperar 15 años o más"
  ),
  orden
)

finales <- tray[tray$mes == meses, ]
finales$etiqueta <- paste0("US$ ", fmt_miles(finales$valor))

# El año 4 va resaltado: es el horizonte corto del aporte de US$ 4.000.
linea_pension <- 4

base <- ggplot(tray, aes(x = anio, y = valor, color = serie, group = serie)) +
  geom_vline(
    xintercept = c(5, 10, 15),
    color = "#C4B49A",
    linewidth = 0.4,
    linetype = "dashed"
  ) +
  geom_vline(
    xintercept = linea_pension,
    color = "#8C3A3A",
    linewidth = 0.7
  ) +
  geom_line(linewidth = 1.15) +
  scale_color_manual(values = pal, breaks = orden, labels = etiquetas_serie, name = NULL) +
  scale_x_continuous(
    breaks = c(0, 4, 5, 10, 15),
    limits = c(0, anios),
    expand = expansion(mult = c(0.01, 0.03))
  ) +
  scale_y_continuous(
    labels = function(x) ifelse(abs(x) < 1, "0", paste0(fmt_miles(x / 1e6), " M")),
    expand = expansion(mult = c(0.02, 0.10))
  ) +
  labs(
    title = "El tiempo que queda cambia el tamaño del aporte",
    subtitle = paste0(
      "Misma tasa de juguete: 15% anual, capitalizada cada mes. Capital inicial US$ 0.\n",
      "Quien está a unos 4 años de la pensión aporta US$ 4.000. ",
      "Quien tiene 10 a 15 años, US$ 2.000. Quien puede esperar, US$ 500."
    ),
    x = "Años",
    y = "Valor acumulado (millones de USD)",
    caption = paste(
      "Simulación educativa. No es un plan de pensión, ni asesoría, ni una promesa de rentabilidad.",
      "Una tasa fija del 15% solo sirve para comparar horizontes. El mercado no paga eso todos los meses.",
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
    legend.text = element_text(colour = tinta, size = 10),
    plot.margin = margin(14, 22, 10, 12)
  )

# Etiquetas de los cortes, arriba, alternando para que el 4 y el 5 no se monten.
y_top <- max(tray$valor)
ann <- data.frame(
  anio = c(4, 5, 10),
  y = c(y_top * 0.96, y_top * 0.84, y_top * 0.96),
  etiqueta = c("Año 4 · pensión", "Año 5", "Año 10"),
  hjust = c(1.08, -0.08, 1.08),
  stringsAsFactors = FALSE
)
# Valores finales hacia adentro, para que no los corte el margen.
finales$hjust <- 1.08
finales$vjust <- ifelse(
  finales$aporte_mensual >= 4000, -0.85,
  ifelse(finales$aporte_mensual >= 2000, 1.55, -0.85)
)

estatico <- base +
  geom_point(
    data = tray[tray$anio %in% cortes_anios, ],
    size = 2.1,
    show.legend = FALSE
  ) +
  geom_text(
    data = ann,
    aes(x = anio, y = y, label = etiqueta, hjust = hjust),
    inherit.aes = FALSE,
    size = 3.1,
    colour = "#5C5144",
    fontface = "bold",
    family = "DejaVu Sans"
  ) +
  geom_text(
    data = finales,
    aes(label = etiqueta, hjust = hjust, vjust = vjust),
    size = 3.3,
    fontface = "bold",
    show.legend = FALSE,
    family = "DejaVu Sans"
  )

png_path <- file.path(dir_salida, "apendice_tres_aportes.png")
ggsave(
  png_path, estatico,
  width = 11.4, height = 7.3, dpi = 150, bg = fondo, device = grDevices::png
)

animado <- base +
  geom_point(
    data = tray[tray$anio %in% cortes_anios, ],
    size = 1.6,
    show.legend = FALSE
  ) +
  transition_reveal(mes) +
  labs(
    title = "Mismo 15%. Lo que cambia es cuánto tiempo te queda",
    subtitle = "US$ 4.000/mes si faltan ~4 años  ·  US$ 2.000 si el horizonte es 10–15  ·  US$ 500 si puedes esperar",
    caption = "Simulación educativa. No es plan de pensión ni promesa de rentabilidad.  @Andalejo1109"
  ) +
  theme(
    plot.title = element_text(size = 16, margin = margin(b = 6)),
    plot.subtitle = element_text(size = 11, margin = margin(b = 8)),
    plot.caption = element_text(size = 9, margin = margin(t = 12)),
    axis.title.x = element_text(margin = margin(t = 8)),
    plot.margin = margin(16, 20, 16, 14)
  )

gif_path <- file.path(dir_salida, "apendice_tres_aportes.gif")
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
