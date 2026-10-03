# apendice_replay_mensual.R
# Replay de la senda mensual real del núcleo. No usa una CAGR constante.
# Alejandro Rodríguez (@Andalejo1109)
#
# Tesis que ilustra (no es asesoría, ni un plan de pensión, ni una promesa,
# ni un pronóstico): el camino largo tiene meses malos. Aquí no se suaviza.
#
# Cada mes se aplica, en el orden histórico, el retorno del núcleo long-only
# ya medido en apendice_retorno_real.R:
#   r_p = 0,31*r_SPYG + 0,22*r_SMH + 0,20*r_BRK.B + 0,20*r_IEMG + 0,07*r_VTI
# con cierres ajustados de Yahoo Finance, rebalanceo mensual.
# Ventana de precios: 31 oct 2012 -> 30 sep 2026. 167 meses de retorno
# (nov 2012 -> sep 2026). No se inventan precios: si falta el CSV, el script para.
#
# Convención de caja (la misma de interescompuesto.R y apendice_retorno_real.R):
#   el saldo del cierre anterior gana el retorno de ESE mes histórico;
#   después entra el aporte y ese aporte NO gana el retorno del mes en que entra.
#   valor_m = valor_(m-1) * (1 + r_m) + PMT
#   aportado_m = P0 + PMT * m
#   mes 0 = solo el capital inicial, sin retorno y sin aporte.
# No es "aporte primero y luego el retorno". Documentado a propósito para
# que el replay sea comparable con los apéndices de tasa constante.
#
# 15 años = 180 meses. La muestra tiene 167. Los meses 168 a 180 REPITEN
# el retorno desde el inicio de la muestra (nov 2012 en adelante).
# En una senda de 15 años el ciclo 2012-2026 no cabe dos veces: 2020 y 2022
# aparecen UNA vez, dentro de la historia real. El tramo repetido es solo
# el arranque (nov 2012 hasta el mes que complete 180).
# La senda "muestra_real" se corta en el mes 167 y no repite nada.

# ===================== CONFIG (edita aquí) =====================
anios        <- 15
cortes_anios <- c(5, 10, 15)
marca_pension <- 4

pesos <- c(
  SPYG    = 0.31,
  SMH     = 0.22,
  "BRK-B" = 0.20,
  IEMG    = 0.20,
  VTI     = 0.07
)

archivo_precios <- "datos/precios_ajustados_mes.csv"
archivo_retornos_previos <- "salida/retorno_portafolio_mensual.csv"

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
  vjust_final = c(-0.55, 1.35, -0.55),
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

if (abs(sum(pesos) - 1) > 1e-12) stop("Los pesos del núcleo no suman 1.")

ruta_px <- file.path(script_dir, archivo_precios)
if (!file.exists(ruta_px)) stop("No está el CSV de precios: ", ruta_px)

px <- read.csv(ruta_px, check.names = FALSE, stringsAsFactors = FALSE)
tickers <- names(pesos)
if (!all(tickers %in% names(px))) {
  stop("Faltan columnas: ", paste(setdiff(tickers, names(px)), collapse = ", "))
}
if (!("fecha" %in% names(px))) stop("El CSV de precios no tiene columna fecha.")

px <- px[order(px$fecha), ]
mat <- as.matrix(px[, tickers])
storage.mode(mat) <- "numeric"
if (any(!is.finite(mat)) || any(mat <= 0)) {
  stop("Hay precios vacíos, no finitos o no positivos. No se inventan huecos.")
}

ret_activos <- mat[-1, , drop = FALSE] / mat[-nrow(mat), , drop = FALSE] - 1
rp <- as.numeric(ret_activos %*% pesos)
fechas_ret <- px$fecha[-1]
n_ret <- length(rp)
fecha_inicio <- px$fecha[1]
fecha_fin <- px$fecha[nrow(px)]

ruta_prev <- file.path(script_dir, archivo_retornos_previos)
if (file.exists(ruta_prev)) {
  prev <- read.csv(ruta_prev, stringsAsFactors = FALSE)
  if (nrow(prev) != n_ret || any(prev$fecha_fin != fechas_ret)) {
    stop("retorno_portafolio_mensual.csv no coincide en fechas con los precios.")
  }
  dif <- max(abs(prev$retorno_portafolio - rp))
  if (dif > 1e-9) {
    stop("Los retornos recalculados no coinciden con el CSV previo. dif = ", dif)
  }
  cat("Control: retornos recalculados = CSV previo. dif máx",
      format(dif, scientific = TRUE), "\n")
}

riqueza <- prod(1 + rp)
cagr <- riqueza^(12 / n_ret) - 1

# Drawdown del núcleo en la muestra (sin aportes). Índice = 1 el día ancla.
indice_muestra <- c(1, cumprod(1 + rp))
fechas_indice <- c(fecha_inicio, fechas_ret)
pico_m <- cummax(indice_muestra)
dd_m <- indice_muestra / pico_m - 1
i_trough <- which.min(dd_m)
i_peak <- max(which(indice_muestra[seq_len(i_trough)] == pico_m[i_trough]))
max_dd <- dd_m[i_trough]
i_recup <- NA_integer_
for (i in seq.int(i_trough, length(indice_muestra))) {
  if (indice_muestra[i] >= indice_muestra[i_peak]) {
    i_recup <- i
    break
  }
}
i_peor_mes <- which.min(rp) + 1L  # +1 porque el índice incluye el ancla en la posición 1

cat("\nNúcleo, rebalanceo mensual, precios ajustados.\n")
cat("Precios:", fecha_inicio, "->", fecha_fin, "\n")
cat("Meses de retorno:", n_ret, sprintf("(%.6f años)\n", n_ret / 12))
cat("Riqueza de 1 USD:", sprintf("%.10f", riqueza), "\n")
cat("CAGR (solo referencia, NO se usa en el replay):",
    sprintf("%.8f%%\n", cagr * 100))
cat(sprintf(
  "Max drawdown del núcleo: %.8f%%  pico %s (índice %.6f)  valle %s (índice %.6f)\n",
  100 * max_dd, fechas_indice[i_peak], indice_muestra[i_peak],
  fechas_indice[i_trough], indice_muestra[i_trough]
))
if (!is.na(i_recup)) {
  cat("Recuperación del pico anterior:", fechas_indice[i_recup], "\n")
}
cat(sprintf(
  "Peor mes suelto: %s  retorno %.8f%%\n\n",
  fechas_ret[which.min(rp)], 100 * min(rp)
))

# Mes del inversor: el ancla (mes 0) es fecha_inicio. El mes k aplica fechas_ret[k].
mes_trough <- i_trough - 1L
mes_peak <- i_peak - 1L
mes_peor <- which.min(rp)

simular <- function(p0, pmt, retornos) {
  n <- length(retornos)
  valor <- numeric(n + 1)
  aportado <- numeric(n + 1)
  valor[1] <- p0
  aportado[1] <- p0
  if (n > 0) {
    for (m in seq_len(n)) {
      valor[m + 1] <- valor[m] * (1 + retornos[m]) + pmt
      aportado[m + 1] <- p0 + pmt * m
    }
  }
  data.frame(
    mes = 0:n,
    anio = (0:n) / 12,
    valor = valor,
    aportado = aportado,
    ganancia = valor - aportado,
    stringsAsFactors = FALSE
  )
}

armar_senda <- function(retornos, fechas_r, ciclos, nombre_senda) {
  n <- length(retornos)
  indice <- c(1, cumprod(1 + retornos))
  pico <- cummax(indice)
  dd_nucleo <- indice / pico - 1
  trozos <- lapply(seq_len(nrow(escenarios)), function(i) {
    e <- escenarios[i, ]
    d <- simular(e$p0, e$pmt, retornos)
    d$senda <- nombre_senda
    d$clave <- e$clave
    d$serie <- e$serie
    d$horizonte <- e$horizonte
    d$aporte_mensual <- e$pmt
    d$capital_inicial <- e$p0
    d$vjust_final <- e$vjust_final
    d$ciclo <- c(0L, ciclos)
    d$fecha_retorno_historica <- c(fecha_inicio, fechas_r)
    d$retorno_portafolio <- c(NA_real_, retornos)
    d$indice_nucleo <- indice
    d$drawdown_nucleo <- dd_nucleo
    pico_c <- cummax(d$valor)
    d$drawdown_cuenta <- ifelse(pico_c > 0, d$valor / pico_c - 1, 0)
    d
  })
  out <- do.call(rbind, trozos)
  rownames(out) <- NULL
  out
}

n_15 <- anios * 12
idx_loop <- ((seq_len(n_15) - 1L) %% n_ret) + 1L
ciclo_loop <- ((seq_len(n_15) - 1L) %/% n_ret) + 1L

tray_15 <- armar_senda(rp[idx_loop], fechas_ret[idx_loop], ciclo_loop, "ciclo_15a")
tray_real <- armar_senda(rp, fechas_ret, rep(1L, n_ret), "muestra_real")

# Los primeros 167 meses tienen que ser idénticos.
chk <- merge(
  tray_15[tray_15$mes <= n_ret, c("clave", "mes", "valor")],
  tray_real[, c("clave", "mes", "valor")],
  by = c("clave", "mes"),
  suffixes = c("_15", "_real")
)
dif_sendas <- max(abs(chk$valor_15 - chk$valor_real))
if (dif_sendas > 1e-8) {
  stop("La senda de 15 años no reproduce la muestra en los primeros meses. dif = ", dif_sendas)
}
cat("Control: meses 0 a", n_ret, "idénticos entre ciclo_15a y muestra_real. dif",
    format(dif_sendas, scientific = TRUE), "\n")

# Control de convención, mes 1 de Alejandro.
r1 <- rp[1]
vf1 <- 70000 * (1 + r1) + 1500
sim1 <- tray_15$valor[tray_15$clave == "alejandro" & tray_15$mes == 1]
if (abs(vf1 - sim1) > 1e-8) stop("Falló el control del mes 1 de Alejandro.")
cat(sprintf("Control mes 1 Alejandro: %.6f USD (70000*(1+r)+1500)\n\n", sim1))

orden <- escenarios$serie
tray_15$serie <- factor(tray_15$serie, levels = orden)
tray_real$serie <- factor(tray_real$serie, levels = orden)

mensual <- rbind(tray_15, tray_real)
mensual <- mensual[order(match(mensual$senda, c("ciclo_15a", "muestra_real")),
                         match(mensual$serie, orden), mensual$mes), ]
rownames(mensual) <- NULL

csv_mensual <- file.path(dir_salida, "apendice_replay_mensual.csv")
cols_csv <- c(
  "senda", "clave", "serie", "horizonte", "capital_inicial", "aporte_mensual",
  "mes", "anio", "ciclo", "fecha_retorno_historica", "retorno_portafolio",
  "indice_nucleo", "drawdown_nucleo", "valor", "aportado", "ganancia",
  "drawdown_cuenta"
)
write.csv(
  mensual[, cols_csv],
  csv_mensual,
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

fila_hito <- function(d, mes, hito) {
  s <- d[d$mes == mes, ]
  s$hito <- hito
  s
}

hitos <- rbind(
  fila_hito(tray_15, 5 * 12, "anio_5"),
  fila_hito(tray_15, 10 * 12, "anio_10"),
  fila_hito(tray_15, 15 * 12, "anio_15"),
  fila_hito(tray_15, n_ret, "fin_muestra_real"),
  fila_hito(tray_15, mes_trough, "peor_drawdown_nucleo"),
  fila_hito(tray_15, mes_peor, "peor_mes_retorno_nucleo")
)

peor_cuenta <- do.call(rbind, lapply(split(tray_15, tray_15$clave), function(s) {
  # El mes 0 no es una caída. El drawdown se mide sobre el saldo.
  k <- which.min(s$drawdown_cuenta)
  s[k, ]
}))
peor_cuenta$hito <- "peor_drawdown_cuenta"
hitos <- rbind(hitos, peor_cuenta)
rownames(hitos) <- NULL

cortes <- data.frame(
  senda = hitos$senda,
  hito = hitos$hito,
  clave = hitos$clave,
  escenario = as.character(hitos$serie),
  horizonte = hitos$horizonte,
  mes = hitos$mes,
  anio = hitos$anio,
  ciclo = hitos$ciclo,
  fecha_retorno_historica = hitos$fecha_retorno_historica,
  retorno_portafolio = hitos$retorno_portafolio,
  drawdown_nucleo = hitos$drawdown_nucleo,
  drawdown_cuenta = hitos$drawdown_cuenta,
  capital_inicial_usd = hitos$capital_inicial,
  aporte_mensual_usd = hitos$aporte_mensual,
  capital_aportado_usd = hitos$aportado,
  valor_usd = hitos$valor,
  ganancia_usd = hitos$ganancia,
  stringsAsFactors = FALSE
)
cortes <- cortes[order(match(cortes$hito, c(
  "anio_5", "anio_10", "anio_15", "fin_muestra_real",
  "peor_drawdown_nucleo", "peor_mes_retorno_nucleo", "peor_drawdown_cuenta"
)), match(cortes$escenario, orden)), ]
rownames(cortes) <- NULL

csv_cortes <- file.path(dir_salida, "apendice_replay_cortes.csv")
write.csv(cortes, csv_cortes, row.names = FALSE, fileEncoding = "UTF-8")

cat("---- Cortes y hitos (USD, sin redondear) ----\n")
print(cortes[, c(
  "hito", "escenario", "mes", "fecha_retorno_historica",
  "retorno_portafolio", "capital_aportado_usd", "valor_usd",
  "ganancia_usd", "drawdown_nucleo", "drawdown_cuenta"
)], row.names = FALSE, digits = 10)
cat("\n")

fmt_miles <- function(x) {
  format(round(x), big.mark = ".", decimal.mark = ",", scientific = FALSE, trim = TRUE)
}
fmt_pct <- function(x, digitos = 2) {
  format(round(x * 100, digitos), nsmall = digitos, decimal.mark = ",",
         scientific = FALSE, trim = TRUE)
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

plot_df <- tray_15
finales <- plot_df[plot_df$mes == n_15, ]
finales$etiqueta <- paste0("US$ ", fmt_miles(finales$valor))

# Meses duros del núcleo (retorno <= -8%), para que el gráfico no parezca liso.
duros <- unique(plot_df[which(plot_df$retorno_portafolio <= -0.08), "mes"])
marcas_duras <- plot_df[plot_df$mes %in% duros, ]

valle <- plot_df[plot_df$mes == mes_trough, ]
valle_y <- max(valle$valor)

anio_valle <- mes_trough / 12
anio_covid <- mes_peor / 12
anio_fin_real <- n_ret / 12

subtitulo <- paste0(
  "Replay del retorno mensual del núcleo (SPYG 31% · SMH 22% · BRK.B 20% · IEMG 20% · VTI 7%).\n",
  "Historia real ", fecha_inicio, " a ", fecha_fin, " (", n_ret, " meses). ",
  "Para completar 15 años se repite el ciclo desde el inicio: ",
  "2020 y 2022 salen una sola vez."
)

base <- ggplot(plot_df, aes(x = anio, y = valor, color = serie, group = serie)) +
  geom_vline(
    xintercept = c(5, 10, 15),
    color = "#C4B49A",
    linewidth = 0.35,
    linetype = "dashed"
  ) +
  geom_vline(
    xintercept = marca_pension,
    color = "#8C3A3A",
    linewidth = 0.55
  ) +
  geom_vline(
    xintercept = anio_valle,
    color = "#8C3A3A",
    linewidth = 0.45,
    linetype = "dotted"
  ) +
  geom_vline(
    xintercept = anio_fin_real,
    color = "#7A6E5F",
    linewidth = 0.4,
    linetype = "dotdash"
  ) +
  geom_line(linewidth = 0.85) +
  geom_point(
    data = marcas_duras,
    size = 1.7,
    show.legend = FALSE
  ) +
  scale_color_manual(values = pal, breaks = orden, labels = etiquetas_serie, name = NULL) +
  scale_x_continuous(
    breaks = c(0, 4, 5, 10, 15),
    limits = c(0, anios),
    expand = expansion(mult = c(0.01, 0.04))
  ) +
  scale_y_continuous(
    labels = function(x) ifelse(abs(x) < 1, "0", paste0(fmt_miles(x / 1e6), " M")),
    expand = expansion(mult = c(0.02, 0.12))
  ) +
  labs(
    title = "Quince años con los meses malos de verdad, no con una tasa lisa",
    subtitle = subtitulo,
    x = "Años del inversor",
    y = "Valor al cierre del mes (millones de USD)",
    caption = paste(
      paste0(
        "Puntos: meses del núcleo con retorno de -8% o peor. ",
        "Raya punteada: peor drawdown del núcleo (",
        fechas_indice[i_trough], ", ", fmt_pct(max_dd),
        "% desde el pico del ", fechas_indice[i_peak], ")."
      ),
      paste0(
        "Raya y punto (año ", format(round(anio_fin_real, 1), decimal.mark = ",", nsmall = 1),
        "): termina la historia real. Lo que sigue repite retornos desde ",
        fechas_ret[1], ". No es un pronóstico."
      ),
      "Aporte al cierre, después del retorno del mes. Simulación educativa. @Andalejo1109",
      sep = "\n"
    )
  ) +
  theme_minimal(base_size = 13, base_family = "DejaVu Sans") +
  theme(
    plot.background = element_rect(fill = fondo, color = NA),
    panel.background = element_rect(fill = fondo, color = NA),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "#E7DCC8", linewidth = 0.35),
    plot.title = element_text(face = "bold", colour = tinta, size = 15.5, margin = margin(b = 6)),
    plot.subtitle = element_text(colour = "#5C5144", size = 10, lineheight = 1.12),
    plot.caption = element_text(colour = "#7A6E5F", hjust = 0, size = 8.6, lineheight = 1.05),
    axis.title = element_text(colour = tinta),
    axis.text = element_text(colour = "#4A4036"),
    legend.position = "top",
    legend.text = element_text(colour = tinta, size = 9.2),
    plot.margin = margin(14, 22, 10, 12)
  ) +
  guides(color = guide_legend(nrow = 3, byrow = TRUE))

ann <- data.frame(
  anio = c(4, anio_valle),
  y = c(max(plot_df$valor) * 0.97, max(plot_df$valor) * 0.78),
  etiqueta = c(
    "Año 4 · pensión",
    paste0("Peor caída del núcleo\n", fmt_pct(max_dd), "% · ", fechas_indice[i_trough])
  ),
  hjust = c(1.06, 1.05),
  stringsAsFactors = FALSE
)

estatico <- base +
  geom_point(
    data = plot_df[plot_df$mes %in% c(5 * 12, 10 * 12, 15 * 12, n_ret, mes_trough), ],
    size = 2.15,
    show.legend = FALSE
  ) +
  geom_text(
    data = ann,
    aes(x = anio, y = y, label = etiqueta, hjust = hjust),
    inherit.aes = FALSE,
    size = 3.05,
    colour = "#5C5144",
    fontface = "bold",
    family = "DejaVu Sans",
    lineheight = 0.95
  ) +
  geom_text(
    data = finales,
    aes(label = etiqueta, hjust = 1.04, vjust = vjust_final),
    size = 3.2,
    fontface = "bold",
    show.legend = FALSE,
    family = "DejaVu Sans"
  )

png_path <- file.path(dir_salida, "apendice_replay_mensual.png")
ggsave(
  png_path, estatico,
  width = 12.2, height = 7.8, dpi = 150, bg = fondo, device = grDevices::png
)

animado <- base +
  geom_point(size = 1.15, show.legend = FALSE) +
  transition_reveal(mes) +
  labs(
    title = "Los mismos aportes, con las caídas del núcleo en el orden en que ocurrieron",
    subtitle = "US$ 4.000/mes desde cero  ·  US$ 500/mes desde cero  ·  Alejandro: US$ 70.000 + US$ 1.500/mes",
    caption = "Replay del pasado (2012-2026, y un tramo repetido al final). No es un pronóstico. @Andalejo1109"
  ) +
  theme(
    plot.title = element_text(size = 13.5, margin = margin(b = 6)),
    plot.subtitle = element_text(size = 10, margin = margin(b = 8)),
    plot.caption = element_text(size = 9, margin = margin(t = 10)),
    axis.title.x = element_text(margin = margin(t = 8)),
    plot.margin = margin(16, 20, 16, 14)
  )

gif_path <- file.path(dir_salida, "apendice_replay_mensual.gif")
anim <- animate(
  animado,
  nframes = 60,
  fps = 10,
  width = 960,
  height = 640,
  res = 100,
  renderer = magick_renderer(loop = TRUE),
  bg = fondo,
  device = "png"
)
anim_save(gif_path, animation = anim)

cat("PNG:", png_path, "\n")
cat("GIF:", gif_path, "\n")
cat("CSV mensual:", csv_mensual, "\n")
cat("CSV cortes:", csv_cortes, "\n")
