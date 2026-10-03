# Tiempo y aportes, no de la noche a la mañana

Simulación educativa de interés compuesto para acompañar una tesis de inversionista de largo plazo. No es asesoría, no es una promesa y no es un resultado de mercado.

> Para llegar a evidenciar ganancias se necesita tiempo y aportes a capital, no es que inicies con 200$ o 1000$ y lograrás 50000$ o 100000$ de la noche a la mañana; tienes que acompañar tu estrategia, continuar haciendo aportes a capital, darle tiempo y que el mercado esté a tu favor.

Alejandro Rodríguez · [@Andalejo1109](https://github.com/Andalejo1109)

## Qué muestra

Con el escenario por defecto (editable arriba del script):

- Capital inicial: **US$ 1.000**
- Aporte: **US$ 200 al cierre de cada mes**
- Horizonte: **15 años** (180 meses)
- Tasas nominales anuales: **10%, 18% y 23%**, capitalizadas cada mes (`r = tasa / 12`)
- Contraste: el mismo inicial, al **18%**, **sin volver a aportar**

La idea es ver, en un solo gráfico, que el camino lo hacen el tiempo y los aportes. La línea punteada se queda pequeña justo porque no se sigue alimentando el capital. Nada de esto ocurre de un mes para otro.

## Fórmula

Anualidad ordinaria (el aporte entra al final del mes):

```
r = tasa_anual / 12
n = años × 12

VF = P × (1 + r)^n  +  PMT × (((1 + r)^n − 1) / r)
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
```

Salida en `salida/`:

- `trayectoria.png` — gráfico estático
- `trayectoria.gif` — las cuatro sendas creciendo a lo largo de los años
- `valores_finales.csv` — aportado, valor final y ganancia

El apéndice (tres aportes, misma tasa) es otro script. No modifica este escenario:

```bash
Rscript apendice_tres_aportes.R
```

## Cómo cambiar el escenario

Abre `interescompuesto.R` y edita solo el bloque `CONFIG` de arriba:

```r
inicial        <- 1000
aporte_mensual <- 200
anios          <- 15
tasas_anuales  <- c(0.10, 0.18, 0.23)
tasa_contraste <- 0.18
```

Vuelve a correr `Rscript interescompuesto.R`. El CSV y las figuras se reemplazan.

## Apéndice. Tres aportes y el tiempo que queda

El script de arriba no se toca. Este escenario vive en `apendice_tres_aportes.R`.

Aquí la tasa ya no es la pregunta. Es la misma para los tres: un **15% anual de juguete**, capitalizado cada mes. Lo que cambia es **cuánto tiempo le queda a cada quien** y, por eso, cuánto tiene que ir soltando todos los meses.

> Si a uno le faltan unos cuatro años para la pensión, el aporte tiene que ser grande: en este ejemplo, US$ 4.000 al mes. Si el horizonte está entre 10 y 15 años, US$ 2.000 ya cuentan otra historia. Y si uno puede esperar 15 años o más, con US$ 500 mensuales el tiempo hace buena parte del trabajo. No es un plan de pensión ni una promesa de rentabilidad. Es la misma fórmula, para ver que quien tiene poco tiempo no puede arrancar chiquito y esperar un milagro de la noche a la mañana.

- Capital inicial: **US$ 0**. Todo sale de los aportes. Si quieres un inicial distinto, está en el `CONFIG` del apéndice.
- Aporte al cierre de cada mes: **US$ 500**, **US$ 2.000** y **US$ 4.000**
- Tasa nominal: **15% anual**, con `r = 0,15 / 12`
- Se mira el camino a **15 años**, con foto en los años **4, 5, 10 y 15**
- La raya del **año 4** es la marca de quien aporta US$ 4.000: a ese plazo corto es al que le toca el aporte grande

Con inicial en cero, la fórmula es la anualidad ordinaria:

```
VF = PMT × (((1 + r)^n − 1) / r)
capital aportado = PMT × n
ganancia = VF − capital aportado
```

Cifras que imprime el script (USD, al centavo):

| Aporte al mes | Horizonte que ilustra | Año | Capital aportado | Valor | Ganancia |
| --- | --- | ---: | ---: | ---: | ---: |
| US$ 4.000 | Unos 4 años para la pensión | 4 | 192.000,00 | 260.913,55 | 68.913,55 |
| US$ 4.000 | Unos 4 años para la pensión | 5 | 240.000,00 | 354.298,03 | 114.298,03 |
| US$ 4.000 | Unos 4 años para la pensión | 10 | 480.000,00 | 1.100.868,23 | 620.868,23 |
| US$ 4.000 | Unos 4 años para la pensión | 15 | 720.000,00 | 2.674.027,04 | 1.954.027,04 |
| US$ 2.000 | Horizonte de 10 a 15 años | 4 | 96.000,00 | 130.456,78 | 34.456,78 |
| US$ 2.000 | Horizonte de 10 a 15 años | 5 | 120.000,00 | 177.149,02 | 57.149,02 |
| US$ 2.000 | Horizonte de 10 a 15 años | 10 | 240.000,00 | 550.434,12 | 310.434,12 |
| US$ 2.000 | Horizonte de 10 a 15 años | 15 | 360.000,00 | 1.337.013,52 | 977.013,52 |
| US$ 500 | Puede esperar 15 años o más | 4 | 24.000,00 | 32.614,19 | 8.614,19 |
| US$ 500 | Puede esperar 15 años o más | 5 | 30.000,00 | 44.287,25 | 14.287,25 |
| US$ 500 | Puede esperar 15 años o más | 10 | 60.000,00 | 137.608,53 | 77.608,53 |
| US$ 500 | Puede esperar 15 años o más | 15 | 90.000,00 | 334.253,38 | 244.253,38 |

Como el inicial es cero, el saldo es proporcional al aporte. Antes de redondear, el de US$ 2.000 es **exactamente cuatro veces** el de US$ 500, y el de US$ 4.000 es **ocho veces**. No es que al aporte grande “le vaya mejor el mercado”: es que cada mes pone ocho veces más plata. Al centavo, el redondeo puede mover un centavo esa proporción.

### Dos celdas revisadas a mano

`r = 0,15 / 12 = 0,0125`.

**Año 5, aporte US$ 500** (`n = 60`):

```
(1,0125)^60 = 2,107181346951
VF = 500 × (2,107181346951 − 1) / 0,0125 = 44.287,253878
```

Al centavo: **US$ 44.287,25**. Capital aportado: 500 × 60 = **US$ 30.000,00**. Ganancia: **US$ 14.287,25**. Es la fila del CSV.

**Año 4, aporte US$ 4.000** (`n = 48`), la marca de pensión:

```
(1,0125)^48 = 1,815354853053
VF = 4.000 × (1,815354853053 − 1) / 0,0125 = 260.913,552977
```

Al centavo: **US$ 260.913,55**. Capital aportado: 4.000 × 48 = **US$ 192.000,00**. Ganancia: **US$ 68.913,55**. También cuadra con el CSV.

El recorrido mes a mes (`saldo × (1 + r) + aporte`) y esa fórmula cerrada se separan, como máximo, por cerca de **1 × 10⁻⁸ USD**. Es ruido de punto flotante, no otra cuenta.

```bash
Rscript apendice_tres_aportes.R
```

Queda en `salida/`:

- `apendice_tres_aportes.png` — las tres sendas, con la raya del año 4 y cortes en 5, 10 y 15
- `apendice_tres_aportes.gif` — el mismo camino, creciendo mes a mes
- `apendice_cortes.csv` — aportado, valor y ganancia en cada corte

## Aviso

Esto, incluido el apéndice de la pensión, es material **educativo** para conversar sobre horizonte y disciplina de aportes, en el proceso de inversionista y de Popular Investor de largo plazo. No es un plan de retiro, no es una recomendación de compra o venta, no describe el portafolio real de nadie y no garantiza una rentabilidad. Una tasa constante, sea 10%, 15%, 18% o 23%, solo sirve para ilustrar la tesis.
