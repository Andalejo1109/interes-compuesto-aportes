# Tiempo y aportes, no de la noche a la mañana

Simulación educativa de interés compuesto para acompañar una tesis de inversionista de largo plazo. No es asesoría, no es una promesa y no es un resultado garantizado.

> Para llegar a evidenciar ganancias se necesita tiempo y aportes a capital, no es que inicies con 200$ o 1000$ y lograrás 50000$ o 100000$ de la noche a la mañana; tienes que acompañar tu estrategia, continuar haciendo aportes a capital, darle tiempo y que el mercado esté a tu favor.

Alejandro Rodríguez · [@Andalejo1109](https://github.com/Andalejo1109)

## Qué muestra el script base

Con el escenario por defecto de `interescompuesto.R` (editable arriba del script):

- Capital inicial: **US$ 1.000**
- Aporte: **US$ 200 al cierre de cada mes**
- Horizonte: **15 años** (180 meses)
- Tasas nominales anuales de juguete: **10%, 18% y 23%**, capitalizadas cada mes (`r = tasa / 12`)
- Contraste: el mismo inicial, al **18%**, **sin volver a aportar**

La idea es ver, en un solo gráfico, que el camino lo hacen el tiempo y los aportes. La línea punteada se queda pequeña justo porque no se sigue alimentando el capital. Nada de esto ocurre de un mes para otro.

## Fórmula

Anualidad ordinaria (el aporte entra al final del mes). La misma regla sirve para el apéndice:

```
r = tasa_anual / 12
n = años × 12

VF = P × (1 + r)^n  +  PMT × (((1 + r)^n − 1) / r)
capital aportado = P + PMT × n
ganancia = VF − capital aportado
```

- `P` es el capital inicial
- `PMT` es el aporte mensual
- Si `PMT = 0`, queda solo el inicial capitalizado

El script no usa la fórmula cerrada de un golpe: recorre el saldo mes a mes con la misma regla (`saldo × (1 + r) + aporte`) y, al final, coincide con esa expresión.

## Resultado del escenario por defecto

Cifras que imprime `interescompuesto.R` (USD, redondeadas al centavo):

| Escenario | Capital aportado | Valor a 15 años | Ganancia |
| --- | ---: | ---: | ---: |
| 10% con aportes | 37.000,00 | 87.347,99 | 50.347,99 |
| 18% con aportes | 37.000,00 | 195.709,27 | 158.709,27 |
| 23% con aportes | 37.000,00 | 338.196,13 | 301.196,13 |
| 18% solo el inicial | 1.000,00 | 14.584,37 | 13.584,37 |

El mismo punto de partida, sin aportes, termina cerca de US$ 14.600. Con US$ 200 al mes, al 18%, pasa de US$ 195.000. La diferencia no es un golpe de suerte de una noche: son 180 aportes y quince años de capitalización. Y aun así es una **tasa fija de juguete**. En la vida real el mercado no paga un 10%, un 18% ni un 23% todos los meses.

## Cómo correrlo

Hace falta R con `ggplot2`, `gganimate` y `magick`.

```bash
cd interes-compuesto
Rscript interescompuesto.R
Rscript apendice_retorno_real.R
Rscript apendice_replay_mensual.R
```

El script base deja en `salida/`:

- `trayectoria.png` — gráfico estático
- `trayectoria.gif` — las cuatro sendas creciendo a lo largo de los años
- `valores_finales.csv` — aportado, valor final y ganancia

El apéndice con el retorno medido del núcleo es `apendice_retorno_real.R`. No modifica el escenario de arriba. `apendice_tres_aportes.R` queda como la versión anterior, con una tasa de juguete del 15% y con la persona de US$ 2.000 al mes, que este apéndice ya no usa.

## Cómo cambiar el escenario base

Abre `interescompuesto.R` y edita solo el bloque `CONFIG` de arriba:

```r
inicial        <- 1000
aporte_mensual <- 200
anios          <- 15
tasas_anuales  <- c(0.10, 0.18, 0.23)
tasa_contraste <- 0.18
```

Vuelve a correr `Rscript interescompuesto.R`. El CSV y las figuras se reemplazan.

## Apéndice. El retorno que sí dio el núcleo

La tasa de este apéndice **no es 15% ni ninguna cifra inventada**. Es la rentabilidad anualizada del núcleo long-only de la tesis, medida con precios públicos y aplicada constante hacia adelante. Es una curva lisa. El replay con las caídas de verdad está en la sección siguiente, `apendice_replay_mensual.R`.

Tres personas. Se quitó quien aportaba US$ 2.000 al mes.

| Quién | Punto de partida | Nota de horizonte |
| --- | --- | --- |
| A | US$ 0 y **US$ 4.000** al cierre de cada mes | Unos 4 años para la pensión |
| B | US$ 0 y **US$ 500** al cierre de cada mes | Puede esperar 15 años o más |
| Alejandro | **US$ 70.000** hoy y **US$ 1.500** al mes | Popular Investor de largo plazo |

Se mira el camino a **15 años**, con foto en los años **5, 10 y 15**. La raya del año 4 en el gráfico sigue siendo la marca de quien aporta US$ 4.000. No entra en la tabla.

### Qué se midió

Pesos fijos, long-only, sin apalancamiento. Suman 100%:

| Activo | Peso | CAGR del activo en la misma ventana |
| --- | ---: | ---: |
| SPYG | 31% | 17,02% |
| SMH | 22% | 31,70% |
| BRK.B | 20% | 13,42% |
| IEMG | 20% | 6,43% |
| VTI | 7% | 14,48% |

Fuente: cierre ajustado mensual de Yahoo Finance (el precio ajustado incorpora dividendos). Cada punto es el último día hábil del mes en el que los cinco tenían precio.

**Ventana usada: 31 oct 2012 → 30 sep 2026.** Son 168 cierres y **167 meses de retorno** (13,92 años). El primer retorno es el de noviembre de 2012. El último es el de septiembre de 2026. Octubre de 2026 no entra: el mes todavía no había cerrado cuando se armó la serie.

No hay 20 años comunes. IEMG (iShares Core MSCI Emerging Markets) se listó el **18 oct 2012**; en esta descarga el primer día con precio es el 24 oct 2012, y el primer cierre de mes común es el **31 oct 2012**. SPYG, SMH, BRK.B y VTI sí tienen historia más larga. El portafolio no puede empezar antes de que exista el último ETF, así que la ventana es la historia común, no un recorte arbitrario de 20 años.

Método de la tasa: **rebalanceo mensual** a esos pesos. Cada mes

```
r_p = 0,31·r_SPYG + 0,22·r_SMH + 0,20·r_BRK.B + 0,20·r_IEMG + 0,07·r_VTI
riqueza = producto(1 + r_p)
CAGR = riqueza ^ (12 / 167) − 1
```

Un dólar en ese núcleo, rebalanceado cada mes, termina en **US$ 9,5442**. La CAGR es **17,5981% anual** (`0,17598104918429`).

Eso es una rentabilidad ponderada por tiempo (TWR) del portafolio de pesos constantes. No es la rentabilidad que habría tenido cada persona si sus aportes hubieran entrado mes a mes durante esos años.

Si nadie rebalancea y los pesos se van con el mercado, la riqueza sube a unos US$ 15,00 y la CAGR a **21,48%**, sobre todo porque SMH se come el portafolio. Ese número **no se usa**: ya no es el núcleo 31/22/20/20/7 de la tesis. La proyección usa el 17,5981% rebalanceado.

### Cómo se proyecta

No se vuelve a pasar la senda histórica de meses buenos y malos. Se toma **esa CAGR como tasa anual constante** y se capitaliza cada mes con la misma convención del script base:

```
r = 0,17598104918429 / 12 = 0,014665087432024
```

Ojo: `r` es la tasa anual dividida entre 12, no la tasa mensual equivalente `(1 + CAGR)^(1/12) − 1`. Por eso `(1 + r)^12` no es exactamente `1 + CAGR`. Es la misma regla con la que se armaron los escenarios de 10%, 18% y 23%.

### Cortes

Cifras que imprime `apendice_retorno_real.R` (USD, al centavo):

| Quién | Horizonte que ilustra | Año | Capital aportado | Valor | Ganancia |
| --- | --- | ---: | ---: | ---: | ---: |
| US$ 4.000 / mes | Unos 4 años para la pensión | 5 | 240.000,00 | 380.582,05 | 140.582,05 |
| US$ 4.000 / mes | Unos 4 años para la pensión | 10 | 480.000,00 | 1.292.196,82 | 812.196,82 |
| US$ 4.000 / mes | Unos 4 años para la pensión | 15 | 720.000,00 | 3.475.803,42 | 2.755.803,42 |
| US$ 500 / mes | Puede esperar 15 años o más | 5 | 30.000,00 | 47.572,76 | 17.572,76 |
| US$ 500 / mes | Puede esperar 15 años o más | 10 | 60.000,00 | 161.524,60 | 101.524,60 |
| US$ 500 / mes | Puede esperar 15 años o más | 15 | 90.000,00 | 434.475,43 | 344.475,43 |
| Alejandro · US$ 70.000 + US$ 1.500/mes | Popular Investor de largo plazo | 5 | 160.000,00 | 310.390,48 | 150.390,48 |
| Alejandro · US$ 70.000 + US$ 1.500/mes | Popular Investor de largo plazo | 10 | 250.000,00 | 886.201,95 | 636.201,95 |
| Alejandro · US$ 70.000 + US$ 1.500/mes | Popular Investor de largo plazo | 15 | 340.000,00 | 2.265.453,10 | 1.925.453,10 |

Quienes parten de cero siguen siendo proporcionales al aporte: antes de redondear, el de US$ 4.000 es ocho veces el de US$ 500. Alejandro no entra en esa proporción porque arranca con US$ 70.000. A los 15 años queda entre los dos. El capital aportado de Alejandro incluye esos US$ 70.000.

### Celda revisada a mano

Alejandro, año 5. `P = 70.000`, `PMT = 1.500`, `n = 60`.

```
r = 0,17598104918429 / 12 = 0,014665087432024
(1 + r)^60 = 2,395317273501

70.000 × 2,395317273501 = 167.672,209145
1.500 × (2,395317273501 − 1) / 0,014665087432024 = 142.718,270174
VF = 167.672,209145 + 142.718,270174 = 310.390,479319
```

Al centavo: **US$ 310.390,48**. Capital aportado: 70.000 + 1.500 × 60 = **US$ 160.000,00**. Ganancia: **US$ 150.390,48**. Es la fila del CSV.

La misma cuenta, con `P = 0` y `PMT = 500`, da **US$ 47.572,76** en el año 5. También cuadra con el CSV.

El recorrido mes a mes y la fórmula cerrada se separan, como máximo, por cerca de **1,5 × 10⁻⁸ USD**. Es ruido de punto flotante, no otra cuenta.

La riqueza del portafolio (9,5441626300) y la CAGR se recalculan dentro del script a partir de `datos/precios_ajustados_mes.csv`. La tasa no está escrita a mano en `CONFIG`.

```bash
Rscript apendice_retorno_real.R
```

Queda en `salida/`:

- `apendice_retorno_real.png` — las tres sendas, con la raya del año 4 y cortes en 5, 10 y 15
- `apendice_retorno_real.gif` — el mismo camino, creciendo mes a mes
- `apendice_retorno_real_cortes.csv` — aportado, valor y ganancia en cada corte
- `medicion_retorno.csv` — ventana, riqueza, CAGR usada y CAGR buy-and-hold que no se usa
- `retorno_portafolio_mensual.csv` — el retorno mensual del núcleo rebalanceado

Los precios de origen están en `datos/precios_ajustados_mes.csv`. El PNG y el GIF se generan al correr el script. La API de GitHub no acepta esos binarios por aquí, así que en el repo quedan los CSV.

## Apéndice. Replay mensual, con las caídas

Esto **rejuega meses pasados**. No es un pronóstico, no es una tasa lisa y no promete que el camino se repita.

Las tres personas son las mismas. Ya no está quien aportaba US$ 2.000 al mes. Cada mes se aplica el retorno histórico del núcleo, en el orden en que ocurrió, recalculado desde `datos/precios_ajustados_mes.csv` (los mismos 167 meses: 30 nov 2012 → 30 sep 2026). No se inventan precios. La CAGR del 17,5981% queda solo como referencia: **no entra en la cuenta**.

Convención de caja, la misma de los otros scripts: el saldo del cierre anterior gana el retorno de ese mes y **después** entra el aporte. El aporte no gana el mes en que se hace.

```
valor_m = valor_(m−1) × (1 + r_m) + PMT
```

Quince años son 180 meses y la muestra tiene 167. Del mes 168 al 180 el camino **repite el ciclo desde el inicio**: otra vez los retornos de noviembre 2012 a noviembre 2013. El cierre del año 15 aplica el retorno del 29 nov 2013. 2020 y 2022 salen **una sola vez**, dentro de la historia real, no en el tramo repetido. La senda que se detiene en la muestra (mes 167, 13,92 años, cierre 30 sep 2026) es idéntica a esos mismos meses del camino de 15 años. El script lo comprueba.

### Caída del núcleo, sin aportes

Un dólar rebalanceado cada mes a los pesos de la tesis. El drawdown es el valor contra el pico anterior.

| | |
| --- | --- |
| Pico | 31 dic 2021, índice 4,496017 |
| Valle | 30 sep 2022, índice 3,252161 |
| Max drawdown | **−27,6657%** |
| Recuperación de ese pico | 29 dic 2023 |
| Peor mes suelto | 31 mar 2020, **−12,2196%** |

En el replay del inversor ese valle es el **mes 119** (9,92 años). El retorno del núcleo en ese mes fue **−10,0015%**. Marzo de 2020 es el mes 89 (7,42 años).

### Cortes del camino de 15 años

USD al centavo. El año 10 cae en octubre 2022, un mes después del valle: el núcleo todavía estaba **−24,58%** bajo el pico de diciembre 2021. Por eso ese corte queda muy por debajo de la curva lisa del apéndice anterior. No es otro cálculo: es la caída, puesta en la fecha que le toca.

| Quién | Año | Fecha del retorno aplicado | Capital aportado | Valor | Ganancia |
| --- | ---: | --- | ---: | ---: | ---: |
| US$ 4.000 / mes | 5 | 31 oct 2017 | 240.000,00 | 361.060,33 | 121.060,33 |
| US$ 4.000 / mes | 10 | 31 oct 2022 | 480.000,00 | 844.541,44 | 364.541,44 |
| US$ 4.000 / mes | 15 | 29 nov 2013 (ciclo repetido) | 720.000,00 | 3.493.489,12 | 2.773.489,12 |
| US$ 500 / mes | 5 | 31 oct 2017 | 30.000,00 | 45.132,54 | 15.132,54 |
| US$ 500 / mes | 10 | 31 oct 2022 | 60.000,00 | 105.567,68 | 45.567,68 |
| US$ 500 / mes | 15 | 29 nov 2013 (ciclo repetido) | 90.000,00 | 436.686,14 | 346.686,14 |
| Alejandro | 5 | 31 oct 2017 | 160.000,00 | 287.763,31 | 127.763,31 |
| Alejandro | 10 | 31 oct 2022 | 250.000,00 | 554.058,75 | 304.058,75 |
| Alejandro | 15 | 29 nov 2013 (ciclo repetido) | 340.000,00 | 2.160.601,89 | 1.820.601,89 |

Quienes parten de cero siguen en proporción 8 a 1. Alejandro no, porque arranca con US$ 70.000 y ese capital sí comió las caídas.

### Si se corta donde termina la historia

Mes 167, sin repetir el ciclo. Cierre 30 sep 2026. Retorno de ese mes: +2,2343%.

| Quién | Capital aportado | Valor | Ganancia |
| --- | ---: | ---: | ---: |
| US$ 4.000 / mes | 668.000,00 | 2.698.753,19 | 2.030.753,19 |
| US$ 500 / mes | 83.500,00 | 337.344,15 | 253.844,15 |
| Alejandro | 320.500,00 | 1.680.123,83 | 1.359.623,83 |

### El peor mes de cada cuenta

El peor drawdown de las tres cuentas cae en el mismo valle del núcleo, 30 sep 2022. Desde el pico de cada saldo (31 dic 2021) hasta ese valle:

| Quién | Valor en el pico | Valor en el valle | Caída en USD | Drawdown de la cuenta | Retorno del núcleo ese mes |
| --- | ---: | ---: | ---: | ---: | ---: |
| US$ 4.000 / mes | 1.072.189,13 | 806.175,37 | −266.013,76 | −24,81% | −10,0015% |
| US$ 500 / mes | 134.023,64 | 100.771,92 | −33.251,72 | −24,81% | −10,0015% |
| Alejandro | 716.792,09 | 529.967,04 | −186.825,05 | −26,06% | −10,0015% |

Las dos que parten de cero tienen el mismo drawdown en porcentaje porque sus saldos son proporcionales. Alejandro cae un poco más: el capital inicial pesa más que los aportes nuevos, que amortiguan la caída. Aun así la cuenta cae menos que el núcleo (−27,67%), porque en esos nueve meses se siguió aportando.

En marzo 2020, el peor mes suelto (−12,2196%), los saldos quedaron en US$ 488.123,20, US$ 61.015,40 y US$ 342.370,77. El drawdown de la cuenta ahí fue −16,64% para las dos que parten de cero y −17,51% para Alejandro. No es su peor valle: el de 2022 es más hondo.

```bash
Rscript apendice_replay_mensual.R
```

Queda en `salida/`:

- `apendice_replay_mensual.csv` — cierre de cada mes, las tres personas, senda de 15 años y senda que se corta en la muestra
- `apendice_replay_cortes.csv` — años 5, 10 y 15, fin de la muestra, valle del núcleo y peor mes
- `apendice_replay_mensual.png` y `.gif` — el camino de 15 años, con el hueco de 2022 visible

El PNG y el GIF se generan al correr el script. En el repo van el script, este README y los CSV.

## Aviso

Esto es material **educativo** para conversar sobre horizonte y disciplina de aportes, en el proceso de inversionista y de Popular Investor de largo plazo.

El **17,5981%** es lo que rindió, en el pasado y en esa ventana, un portafolio rebalanceado cada mes a los pesos de la tesis. **No es una promesa de que el núcleo vuelva a dar eso**, ni los próximos 5, 10 o 15 años, ni todos los meses. Hubo años negativos en la muestra (2015, 2018, 2022). Un plan de aportes con esa tasa constante es una ilustración, no el camino que va a recorrer el mercado. El replay mensual de arriba tampoco lo es: vuelve a pasar meses que ya ocurrieron, incluido un tramo repetido al final para completar 15 años. **No dice lo que va a pasar los próximos 15.**

Tampoco es un plan de pensión, ni una recomendación de compra o venta, ni una foto del portafolio real de Alejandro en eToro. Los US$ 70.000 y los US$ 1.500 al mes son el punto de partida del ejemplo. Quien está a unos cuatro años de la pensión no debería leer la fila de US$ 4.000 como una meta ni como un cálculo de retiro.
