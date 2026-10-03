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

## Aviso

Esto es material **educativo** para conversar sobre horizonte y disciplina de aportes, en el proceso de inversionista y de Popular Investor de largo plazo. No es una recomendación de compra o venta, no describe el portafolio real de nadie y no garantiza una rentabilidad. Una tasa constante solo sirve para ilustrar la tesis.
