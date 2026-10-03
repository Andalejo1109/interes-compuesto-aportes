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
#
# El objetivo de pensión se marca en el AÑO 5 (mes 60), no en el año 4,
# y esa raya es la misma para las tres personas. No cambia aportes ni retornos.

# ===================== CONFIG (edita aquí) =====================
anios        <- 15
cortes_anios <- c(5, 10, 15)
marca_pension <- 5

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
    "Objetivo de pensión en el año 5",
    "Puede esperar 15 años o más",
    "Popular Investor de largo plazo"
  ),
  archivo_png = c("grafico_4000.png", "grafico_500.png", "grafico_alejandro.png"),
  archivo_gif = c("grafico_4000.gif", "grafico_500.gif", "grafico_alejandro.gif"),
  vjust_final = c(-0.55, 1.35, -0.55),
  stringsAsFactors = FALSE
)
# ===============================================================
