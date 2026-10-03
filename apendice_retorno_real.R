# apendice_retorno_real.R
# Apéndice realista de interescompuesto.R. El script original no se toca.
# Alejandro Rodríguez (@Andalejo1109)
#
# Tesis que ilustra (no es asesoría, ni un plan de pensión, ni una promesa):
#   El tiempo y los aportes siguen siendo el camino. Aquí la tasa ya no es
#   de juguete: es el retorno anualizado que sí dio el núcleo long-only,
#   medido con precios públicos, y se aplica constante hacia adelante.
#
# La tasa NO se escribe a mano en CONFIG. Sale de
#   datos/precios_ajustados_mes.csv
# (cierre ajustado de Yahoo Finance, dividendos en el precio ajustado).
#
# Ventana: primer cierre de mes común después del listado de IEMG
# (18 oct 2012; el archivo arranca el 31 oct 2012) hasta el último mes
# completo, 30 sep 2026. No hay 20 años comunes: IEMG es el límite.
#
# Medición: rebalanceo mensual a los pesos de la tesis. Cada mes
#   r_p = suma(peso_i * r_i), con r_i = P_i,t / P_i,t-1 - 1.
#   CAGR = (producto(1 + r_p)) ^ (12 / n) - 1.
# Eso es una TWR anualizada. No es la rentabilidad ponderada por los
# aportes de cada persona.
#
# Proyección (lo que pidió el apéndice: "el retorno anual"):
#   esa CAGR constante, capitalizada cada mes con r = CAGR / 12,
#   la misma convención que el script original. No se rejuega la senda
#   histórica de retornos mensuales.
#
# Fórmula (anualidad ordinaria, aporte al cierre de cada mes):
#   r = tasa_anual / 12
#   n = años * 12
#   VF = P * (1 + r)^n  +  PMT * (((1 + r)^n - 1) / r)
#   Capital aportado = P + PMT * n
#   Ganancia = VF - capital aportado

# ===================== CONFIG (edita aquí) =====================
anios        <- 15
cortes_anios <- c(5, 10, 15)
# La raya del año 4 es solo la marca de pensión de quien aporta US$ 4.000.
# No entra en la tabla de cortes.
marca_pension <- 4

# Pesos del núcleo long-only de la tesis. Suman 1. Sin apalancamiento.
pesos <- c(
  SPYG   = 0.31,
  SMH    = 0.22,
  "BRK-B" = 0.20,
  IEMG   = 0.20,
  VTI    = 0.07
)

archivo_precios <- "datos/precios_ajustados_mes.csv"

# Tres personas. Ya no está quien aportaba US$ 2.000 al mes.
escenarios <- data.frame(
  clave = c("a4000", "a500", "alejandro"),
  p0 = c(0, 0, 70000),
  pmt = c(4000, 500, 1500),
  serie = c(
    "US$ 4.000 / mes",
    "US$ 500 / mes",
    "Alejandro · US$ 70.000 + US$ 1.500/mes"
  ),
  horizonte = c(
    "Unos 4 años para la pensión",
    "Puede esperar 15 años o más",
    "Popular Investor de largo plazo"
  ),
  vjust_final = c(-0.70, -0.70, 1.55),
  stringsAsFactors = FALSE
)
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

if (abs(sum(pesos) - 1) > 1e-12) {
  stop("Los pesos del núcleo no suman 1.")
}

ruta_px <- file.path(script_dir, archivo_precios)
px <- read.csv(ruta_px, check.names = FALSE, stringsAsFactors = FALSE)
tickers <- names(pesos)
if (!all(tickers %in% names(px))) {
  stop("Faltan columnas en el CSV de precios: ",
       paste(setdiff(tickers, names(px)), collapse = ", "))
}
if (!("fecha" %in% names(px))) stop("El CSV de precios no tiene columna fecha.")

px <- px[order(px$fecha), ]
mat <- as.matrix(px[, tickers])
storage.mode(mat) <- "numeric"
if (any(!is.finite(mat)) || any(mat <= 0)) {
  stop("Hay precios vacíos, no finitos o no positivos.")
}

ret <- mat[-1, , drop = FALSE] / mat[-nrow(mat), , drop = FALSE] - 1
rp <- as.numeric(ret %*% pesos)
n_ret <- length(rp)
riqueza <- prod(1 + rp)
tasa_anual <- riqueza^(12 / n_ret) - 1

fecha_inicio <- px$fecha[1]
fecha_fin <- px$fecha[nrow(px)]

# CAGR de cada activo, misma ventana, solo para dejar constancia.
cagr_activo <- mat[nrow(mat), ] / mat[1, ]
cagr_activo <- cagr_activo^(12 / n_ret) - 1

# Buy-and-hold sin rebalancear (los pesos se van con el mercado).
# No se usa en la proyección. Sirve para no esconder que la deriva
# de SMH sube el CAGR si nadie vuelve a los pesos de la tesis.
riqueza_bh <- sum(pesos * (mat[nrow(mat), ] / mat[1, ]))
cagr_bh <- riqueza_bh^(12 / n_ret) - 1

cat("\nNúcleo long-only, rebalanceo mensual, precios ajustados de Yahoo.\n")
cat("Ventana de precios:", fecha_inicio, "->", fecha_fin, "\n")
cat("Meses de retorno:", n_ret, sprintf("(%.4f años)\n", n_ret / 12))
cat("Riqueza de 1 USD (TWR rebalanceada):", sprintf("%.10f", riqueza), "\n")
cat("CAGR anualizada:", sprintf("%.8f%%", tasa_anual * 100), "\n")
cat("CAGR buy-and-hold (no se usa):", sprintf("%.8f%%", cagr_bh * 100), "\n")
cat("CAGR por activo:\n")
for (k in tickers) {
  cat(sprintf("  %-6s %6.2f%%  CAGR %7.4f%%\n", k, 100 * pesos[[k]], 100 * cagr_activo[[k]]))
}
cat("\n")

med <- data.frame(
  metodo = "TWR mensual rebalanceada a pesos fijos; CAGR = riqueza^(12/n) - 1",
  fuente = "Yahoo Finance adjusted close",
  fecha_inicio = fecha_inicio,
  fecha_fin = fecha_fin,
  n_meses_retorno = n_ret,
  riqueza_1usd = riqueza,
  cagr_anual = tasa_anual,
  cagr_buy_and_hold_no_usada = cagr_bh,
  peso_SPYG = unname(pesos[["SPYG"]]),
  peso_SMH = unname(pesos[["SMH"]]),
  peso_BRKB = unname(pesos[["BRK-B"]]),
  peso_IEMG = unname(pesos[["IEMG"]]),
  peso_VTI = unname(pesos[["VTI"]]),
  cagr_SPYG = unname(cagr_activo[["SPYG"]]),
  cagr_SMH = unname(cagr_activo[["SMH"]]),
  cagr_BRKB = unname(cagr_activo[["BRK-B"]]),
  cagr_IEMG = unname(cagr_activo[["IEMG"]]),
  cagr_VTI = unname(cagr_activo[["VTI"]]),
  stringsAsFactors = FALSE
)
write.csv(
  med,
  file.path(dir_salida, "medicion_retorno.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

ret_out <- data.frame(
  fecha_fin = px$fecha[-1],
  retorno_portafolio = rp,
  indice_riqueza = cumprod(1 + rp),
  stringsAsFactors = FALSE
)
write.csv(
  ret_out,
  file.path(dir_salida, "retorno_portafolio_mensual.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

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

vf_cerrado <- function(p0, pmt, tasa, n_meses) {
  r <- tasa / 12
  p0 * (1 + r)^n_meses + pmt * (((1 + r)^n_meses - 1) / r)
}

meses <- anios * 12
trozos <- lapply(seq_len(nrow(escenarios)), function(i) {
  e <- escenarios[i, ]
  d <- simular(e$p0, e$pmt, tasa_anual, meses)
  d$aporte_mensual <- e$pmt
  d$capital_inicial <- e$p0
  d$serie <- e$serie
  d$horizonte <- e$horizonte
  d$vjust_final <- e$vjust_final
  d
})

tray <- do.call(rbind, trozos)
rownames(tray) <- NULL

orden <- escenarios$serie
tray$serie <- factor(tray$serie, levels = orden)

cortes <- tray[tray$anio %in% cortes_anios, c(
  "serie", "aporte_mensual", "capital_inicial", "horizonte", "anio", "mes",
  "aportado", "valor", "ganancia"
)]
cortes <- cortes[order(match(cortes$serie, orden), cortes$anio), ]
rownames(cortes) <- NULL

cerrado <- mapply(
  vf_cerrado,
  cortes$capital_inicial,
  cortes$aporte_mensual,
  tasa_anual,
  cortes$mes
)
cortes$valor_formula <- as.numeric(cerrado)
cortes$dif_vs_formula <- cortes$valor - cortes$valor_formula

cat("Máxima diferencia simulación vs fórmula cerrada:",
    format(max(abs(cortes$dif_vs_formula)), scientific = TRUE), "USD\n")

# Celda revisada a mano: Alejandro, año 5 (P = 70000, PMT = 1500, n = 60).
r_mes <- tasa_anual / 12
n_mano <- 5 * 12
factor_mano <- (1 + r_mes)^n_mano
vf_mano <- 70000 * factor_mano + 1500 * ((factor_mano - 1) / r_mes)
fila_mano <- cortes$valor[cortes$serie == "Alejandro · US$ 70.000 + US$ 1.500/mes" & cortes$anio == 5]
cat(sprintf("Control a mano, Alejandro año 5: fórmula %.6f  simulación %.6f  dif %.3e\n",
            vf_mano, fila_mano, vf_mano - fila_mano))
cat(sprintf("r mensual = tasa/12 = %.12f\n", r_mes))
cat(sprintf("(1+r)^60 = %.12f\n\n", factor_mano))

out <- data.frame(
  escenario = as.character(cortes$serie),
  aporte_mensual_usd = cortes$aporte_mensual,
  horizonte = cortes$horizonte,
  anio = cortes$anio,
  meses = cortes$mes,
  tasa_anual = tasa_anual,
  convencion = "r = tasa_anual / 12",
  capital_inicial_usd = cortes$capital_inicial,
  capital_aportado_usd = round(cortes$aportado, 2),
  valor_usd = round(cortes$valor, 2),
  ganancia_usd = round(cortes$ganancia, 2),
  ventana_inicio = fecha_inicio,
  ventana_fin = fecha_fin,
  stringsAsFactors = FALSE
)

csv_path <- file.path(dir_salida, "apendice_retorno_real_cortes.csv")
write.csv(out, csv_path, row.names = FALSE, fileEncoding = "UTF-8")

cat("Cortes (USD). Tasa medida", sprintf("%.6f%%", tasa_anual * 100),
    "capitalizada cada mes.\n")
print(out[, c("escenario", "anio", "capital_aportado_usd", "valor_usd", "ganancia_usd")],
      row.names = FALSE, digits = 10)
cat("\n")

fmt_miles <- function(x) {
  format(round(x), big.mark = ".", decimal.mark = ",", scientific = FALSE, trim = TRUE)
}

fmt_pct <- function(x) {
  format(round(x * 100, 3), nsmall = 3, decimal.mark = ",", scientific = FALSE, trim = TRUE)
}

pal <- c(
  "US$ 4.000 / mes" = "#1D4E89",
  "US$ 500 / mes" = "#1B7F6E",
  "Alejandro · US$ 70.000 + US$ 1.500/mes" = "#6E2B4A"
)

fondo <- "#FBF6EF"
tinta <- "#2C2416"

etiquetas_serie <- c(
  "US$ 4.000/mes · unos 4 años para la pensión",
  "US$ 500/mes · puede esperar 15 años o más",
  "Alejandro · US$ 70.000 hoy + US$ 1.500/mes · largo plazo"
)
names(etiquetas_serie) <- orden

finales <- tray[tray$mes == meses, ]
finales$etiqueta <- paste0("US$ ", fmt_miles(finales$valor))
finales$hjust <- 1.06

pct_txt <- paste0(fmt_pct(tasa_anual), "%")

base <- ggplot(tray, aes(x = anio, y = valor, color = serie, group = serie)) +
  geom_vline(
    xintercept = c(5, 10, 15),
    color = "#C4B49A",
    linewidth = 0.4,
    linetype = "dashed"
  ) +
  geom_vline(
    xintercept = marca_pension,
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
    title = "La misma tasa que dio el núcleo, tres maneras de acompañarla",
    subtitle = paste0(
      "Retorno anualizado medido: ", pct_txt,
      " (rebalanceo mensual, ", fecha_inicio, " a ", fecha_fin, ").\n",
      "SPYG 31% · SMH 22% · BRK.B 20% · IEMG 20% · VTI 7%. ",
      "Long-only, sin apalancamiento. La tasa se aplica constante, con r = tasa/12."
    ),
    x = "Años",
    y = "Valor acumulado (millones de USD)",
    caption = paste(
      "Simulación educativa. El retorno pasado del núcleo no es una promesa ni un plan de pensión.",
      "IEMG lista en 2012: no hay 20 años comunes. La cifra es la TWR del portafolio, no la de los aportes.",
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
    plot.title = element_text(face = "bold", colour = tinta, size = 16, margin = margin(b = 6)),
    plot.subtitle = element_text(colour = "#5C5144", size = 10.5, lineheight = 1.15),
    plot.caption = element_text(colour = "#7A6E5F", hjust = 0, size = 9, lineheight = 1.05),
    axis.title = element_text(colour = tinta),
    axis.text = element_text(colour = "#4A4036"),
    legend.position = "top",
    legend.text = element_text(colour = tinta, size = 9.5),
    plot.margin = margin(14, 22, 10, 12)
  ) +
  guides(color = guide_legend(nrow = 3, byrow = TRUE))

y_top <- max(tray$valor)
ann <- data.frame(
  anio = c(4, 5, 10),
  y = c(y_top * 0.97, y_top * 0.84, y_top * 0.97),
  etiqueta = c("Año 4 · pensión", "Año 5", "Año 10"),
  hjust = c(1.08, -0.08, 1.08),
  stringsAsFactors = FALSE
)

estatico <- base +
  geom_point(
    data = tray[tray$anio %in% cortes_anios, ],
    size = 2.2,
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
    aes(label = etiqueta, hjust = hjust, vjust = vjust_final),
    size = 3.3,
    fontface = "bold",
    show.legend = FALSE,
    family = "DejaVu Sans"
  )

png_path <- file.path(dir_salida, "apendice_retorno_real.png")
ggsave(
  png_path, estatico,
  width = 11.6, height = 7.6, dpi = 150, bg = fondo, device = grDevices::png
)

animado <- base +
  geom_point(
    data = tray[tray$anio %in% cortes_anios, ],
    size = 1.6,
    show.legend = FALSE
  ) +
  transition_reveal(mes) +
  labs(
    title = paste0("Núcleo al ", pct_txt, " anual. El tiempo y el aporte hacen el resto"),
    subtitle = "US$ 4.000/mes desde cero  ·  US$ 500/mes desde cero  ·  Alejandro: US$ 70.000 + US$ 1.500/mes",
    caption = "El retorno pasado no es una promesa. Simulación educativa.  @Andalejo1109"
  ) +
  theme(
    plot.title = element_text(size = 14.5, margin = margin(b = 6)),
    plot.subtitle = element_text(size = 10.5, margin = margin(b = 8)),
    plot.caption = element_text(size = 9, margin = margin(t = 12)),
    axis.title.x = element_text(margin = margin(t = 8)),
    plot.margin = margin(16, 20, 16, 14)
  )

gif_path <- file.path(dir_salida, "apendice_retorno_real.gif")
anim <- animate(
  animado,
  nframes = 90,
  fps = 10,
  width = 1320,
  height = 860,
  res = 120,
  renderer = magick_renderer(loop = TRUE),
  bg = fondo,
  device = "png"
)
anim_save(gif_path, animation = anim)

cat("PNG:", png_path, "\n")
cat("GIF:", gif_path, "\n")
cat("CSV:", csv_path, "\n")
