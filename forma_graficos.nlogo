globals [
  co2-acumulado          ; emisiones totales acumuladas (toneladas)
  edad-media-vehiculos   ; edad media de los vehículos (años)
  año
]

breed [vehiculos vehiculo]
breed [personas persona]

vehiculos-own [
  tipo-vehiculo
  tipo-motor
  subtipo-combustion
  consumo-litros
  consumo-kwh
  edad
  tamaño
  coste
  generacion-CO2-comb
  generacion-CO2-elec
  idPropietario
]

personas-own [
  ahorro
  ciudad
  carretera
  motorHead
  idcoche
]

to setup
  clear-all
  set PPRECIO 1.0
  set mix 200
  set co2-acumulado 0
  set edad-media-vehiculos 0

  ;; PERSONAS
  create-personas 100 [
    setxy random-xcor random-ycor
    set shape "person"
    set hidden? true

    let r random-float 100
    if r < 50 [ set ahorro 50 ]
    if r >= 50 and r < 80 [ set ahorro 400 ]
    if r >= 80 [ set ahorro 1500 ]

    asigtipo
    set motorHead random 2
    set idcoche who + 100
  ]

  ;; VEHICULOS
  create-vehiculos 100 [
    setxy random-xcor random-ycor
    asignar-tipo-vehiculo
    set tamaño random 2
    asignar-tipo-motor
    asignar-consumo
    calculo-co2-100-comb
    calculo-co2-100-elec
    set edad random 16
    set idPropietario who - 100

    set color (ifelse-value
      tipo-motor = "electrico"           [ lime ]
      tipo-motor = "hibrido-enchufable"  [ yellow ]
      [ red ])
  ]

  reset-ticks
end

to go
  set año 2024 + (ticks / 12)

  ;; Compras solo una vez al año
  if ticks mod 12 = 0 [
    let candidatas n-of (max (list 1 round (count personas * 0.01))) personas
    let obligadas personas with [ is-vehiculo? vehiculo idcoche and [edad] of vehiculo idcoche >= 20 ]
    ask (turtle-set candidatas obligadas) [
      comprar
    ]
  ]

  ;; Envejecimiento mensual
  ask vehiculos [
    set edad edad + (1 / 12)
  ]

  ;; Movimiento visual
  ask vehiculos [
    set heading 90
    forward 0.2
  ]

  ;; Regla 2055: conversión forzada
  if año >= 2055 [
    ask vehiculos with [tipo-motor = "combustion"] [
      set tipo-motor "electrico"
      set subtipo-combustion ""
      asignar-consumo
      set color lime
    ]
  ]

  ;; Cálculo de edad media y CO₂ acumulado
  ifelse count vehiculos > 0 [
    set edad-media-vehiculos precision ( (sum [edad] of vehiculos) / (count vehiculos) ) 2
  ] [
    set edad-media-vehiculos 0
  ]

  ;; CO₂ mensual → acumulado en toneladas
  let km-por-mes 800                        ; <--- ajusta este valor según escenario
  let factor-toneladas 0.000001             ; gramos → toneladas
  let co2-mensual sum [ (generacion-CO2-comb + generacion-CO2-elec) * (km-por-mes / 100) ] of vehiculos
  set co2-acumulado co2-acumulado + (co2-mensual * factor-toneladas)

  tick
end

to asigtipo
  let tipo random 3
  ifelse tipo = 0 [
    set ciudad 8000
    set carretera 0
  ][
    ifelse tipo = 1 [
      set ciudad 8000
      set carretera 3000
    ][
      set ciudad 8000
      set carretera 30000
    ]
  ]
end

to asignar-tipo-vehiculo
  let r random-float 100
  if r < 66.67 [
    set tipo-vehiculo "turismo"
    set shape "car"
  ]
  if r >= 66.67 and r < 73.35 [
    set tipo-vehiculo "camion"
    set shape "truck"
  ]
  if r >= 73.35 [
    set tipo-vehiculo "furgoneta"
    set shape "sheep"
  ]
end

to asignar-tipo-motor
  let r random-float 100
  set subtipo-combustion ""
  if r < 1.673 [
    set tipo-motor "electrico"
  ]
  if r >= 1.673 and r < 2.483 [
    set tipo-motor "hibrido-enchufable"
  ]
  if r >= 2.483 [
    set tipo-motor "combustion"
    let r2 random-float 100
    ifelse r2 < 97.516 [
      set subtipo-combustion "combustible"
    ][
      set subtipo-combustion "hibrido-no-enchufable"
    ]
  ]
end

to asignar-consumo
  if tipo-vehiculo = "turismo" [
    if tipo-motor = "electrico" [
      set consumo-litros 0
      ifelse tamaño = 0 [
        set consumo-kwh 15
        set coste 30000
      ][
        set consumo-kwh 20
        set coste 40000
      ]
    ]
    if tipo-motor = "hibrido-enchufable" [
      set consumo-litros 5
      set consumo-kwh 15
      set coste 35000
    ]
    if tipo-motor = "combustion" [
      set consumo-kwh 0
      if subtipo-combustion = "combustible" [
        ifelse tamaño = 0 [
          set consumo-litros 6
          set coste 20000
        ][
          set consumo-litros 9
          set coste 35000
        ]
      ]
      if subtipo-combustion = "hibrido-no-enchufable" [
        set consumo-litros 5
        set consumo-kwh 15
        set coste 35000
      ]
    ]
  ]

  if tipo-vehiculo = "furgoneta" [
    if tamaño = 0 [
      set coste 20000
      if tipo-motor = "electrico" [ set consumo-litros 0 set consumo-kwh 17 ]
      if tipo-motor = "hibrido-enchufable" [ set consumo-litros 3 set consumo-kwh 17 ]
      if tipo-motor = "combustion" [
        if subtipo-combustion = "combustible" [ set consumo-litros 6 set consumo-kwh 0 ]
        if subtipo-combustion = "hibrido-no-enchufable" [ set consumo-litros 3 set consumo-kwh 17 ]
      ]
    ]
    if tamaño = 1 [
      set coste 30000
      if tipo-motor = "electrico" [ set consumo-litros 0 set consumo-kwh 27 ]
      if tipo-motor = "hibrido-enchufable" [ set consumo-litros 5 set consumo-kwh 25 ]
      if tipo-motor = "combustion" [
        if subtipo-combustion = "combustible" [ set consumo-litros 10 set consumo-kwh 0 ]
        if subtipo-combustion = "hibrido-no-enchufable" [ set consumo-litros 5 set consumo-kwh 25 ]
      ]
    ]
  ]

  if tipo-vehiculo = "camion" [
    if tamaño = 0 [
      set coste 45000
      if tipo-motor = "electrico" [ set consumo-litros 0 set consumo-kwh 30 ]
      if tipo-motor = "hibrido-enchufable" [ set consumo-litros 6 set consumo-kwh 20 ]
      if tipo-motor = "combustion" [
        if subtipo-combustion = "combustible" [ set consumo-litros 20 set consumo-kwh 0 ]
        if subtipo-combustion = "hibrido-no-enchufable" [ set consumo-litros 6 set consumo-kwh 20 ]
      ]
    ]
    if tamaño = 1 [
      set coste 110000
      if tipo-motor = "electrico" [ set consumo-litros 0 set consumo-kwh 130 ]
      if tipo-motor = "hibrido-enchufable" [ set consumo-litros 25 set consumo-kwh 100 ]
      if tipo-motor = "combustion" [
        if subtipo-combustion = "combustible" [ set consumo-litros 35 set consumo-kwh 0 ]
        if subtipo-combustion = "hibrido-no-enchufable" [ set consumo-litros 25 set consumo-kwh 100 ]
      ]
    ]
  ]
end

to calculo-co2-100-comb
  set generacion-CO2-comb consumo-litros * 2300
end

to calculo-co2-100-elec
  set generacion-CO2-elec (consumo-kwh * mix * 1.53) / 100
end

to comprar
  let miCoche vehiculo idcoche
  if not is-vehiculo? miCoche [ stop ]

  if [edad] of miCoche < 8 [ stop ]

  let mi-motorHead motorHead

  let factor-precio 0.9
  let c-elec-g   (40000 * PPRECIO * factor-precio)
  let c-elec-p   (30000 * PPRECIO * factor-precio)
  let c-hib      (35000 * PPRECIO * factor-precio)
  let c-comb-g   (35000 * PPRECIO * factor-precio)
  let c-comb-p   (20000 * PPRECIO * factor-precio)
  let c-hibno    (35000 * PPRECIO * factor-precio)

  if achatarramiento < 500 [ set achatarramiento 500 ]

  let ahorro-mensual-comb ([consumo-litros] of miCoche * 1.46)
  let ahorro-disponible (ahorro + ahorro-mensual-comb + achatarramiento)

  let divisor-pago 240

  ifelse (member? [tipo-vehiculo] of miCoche ["furgoneta" "camion"]) [
    ask miCoche [
      ifelse (año >= 2055 or mi-motorHead = 0) [
        set tipo-motor "electrico"
        set subtipo-combustion ""
      ] [
        set tipo-motor "combustion"
        set subtipo-combustion "combustible"
      ]
      set edad 0.1
      set tamaño 1
    ]
  ] [
    if ([tipo-vehiculo] of miCoche = "turismo") [
      ifelse (ahorro-disponible >= (c-elec-g / divisor-pago) and mi-motorHead = 0) [
        ask miCoche [ set tipo-motor "electrico" set subtipo-combustion "" set edad 0.1 set tamaño 1 ]
      ] [
      ifelse (ahorro-disponible >= (c-elec-p / divisor-pago) and mi-motorHead = 0) [
        ask miCoche [ set tipo-motor "electrico" set subtipo-combustion "" set edad 0.1 set tamaño 0 ]
      ] [
      ifelse (año < 2035 and ahorro-disponible >= (c-hib / divisor-pago) and mi-motorHead = 0) [
        ask miCoche [ set tipo-motor "hibrido-enchufable" set subtipo-combustion "" set edad 0.1 set tamaño 0 ]
      ] [
      ifelse (año < 2035 and ahorro-disponible >= (c-comb-g / divisor-pago) and mi-motorHead = 1) [
        ask miCoche [ set tipo-motor "combustion" set subtipo-combustion "combustible" set edad 0.1 set tamaño 1 ]
      ] [
      ifelse (año < 2035 and ahorro-disponible >= (c-comb-p / divisor-pago) and mi-motorHead = 1) [
        ask miCoche [ set tipo-motor "combustion" set subtipo-combustion "combustible" set edad 0.1 set tamaño 0 ]
      ] [

        ;; SEGUNDA MANO
        let precio-base 0
        ask miCoche [
          ifelse (mi-motorHead = 0 or año >= 2055) [
            set precio-base (c-elec-p * 0.4)
            set tipo-motor "electrico"
            set subtipo-combustion ""
            set tamaño 0
          ] [
            set precio-base (c-comb-p * 0.4)
            set tipo-motor "combustion"
            set subtipo-combustion "combustible"
            set tamaño 0
          ]
        ]

        let edad-nueva floor (precio-base / (ahorro-disponible * divisor-pago * 0.7))

        if edad-nueva > 19 [
          matar-coche
          stop
        ]

        if edad-nueva < 2 [ set edad-nueva 2 ]

        ask miCoche [ set edad edad-nueva ]
      ]]]]]]
    ]


  ask miCoche [
    asignar-consumo
    calculo-co2-100-comb
    calculo-co2-100-elec
    set color (ifelse-value
      tipo-motor = "electrico"           [ lime ]
      tipo-motor = "hibrido-enchufable"  [ yellow ]
      [ red ])
  ]
end

to matar-coche
  ask vehiculo idcoche [ die ]
end
@#$#@#$#@
GRAPHICS-WINDOW
286
10
1051
776
-1
-1
12.41
1
10
1
1
1
0
1
1
1
-30
30
-30
30
0
0
1
ticks
30.0

PLOT
1084
17
1620
289
vehiculos
NIL
NIL
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"combustion" 1.0 0 -5298144 true "" "plot count vehiculos with [tipo-motor = \"combustion\"]"
"electrico" 1.0 0 -14439633 true "" "plot count vehiculos with [tipo-motor = \"electrico\"]"
"hibrido enchufable" 1.0 0 -1184463 true "" "plot count vehiculos with [tipo-motor = \"hibrido-enchufable\"]"

PLOT
1084
560
1620
773
CO2
NIL
NIL
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"valor" 1.0 0 -16777216 true "" "plot co2-acumulado"

BUTTON
127
18
190
51
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
61
18
124
51
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
35
68
268
101
motorhead_porcentaje
motorhead_porcentaje
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
35
109
267
142
mix
mix
0
200
200.0
1
1
NIL
HORIZONTAL

SLIDER
35
150
267
183
autoplus
autoplus
0
20000
13200.0
100
1
NIL
HORIZONTAL

SLIDER
35
191
267
224
achatarramiento
achatarramiento
0
5000
2000.0
100
1
NIL
HORIZONTAL

SLIDER
34
230
267
263
IVTM
IVTM
0
100
75.0
1
1
NIL
HORIZONTAL

PLOT
1084
297
1362
549
tipo de vehículos
NIL
NIL
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"turismos" 1.0 0 -8330359 true "" "plot count vehiculos with [tipo-vehiculo = \"turismo\"]"
"camiones" 1.0 0 -13791810 true "" "plot count vehiculos with [tipo-vehiculo = \"camion\"]"
"furgonetas" 1.0 0 -2674135 true "" "plot count vehiculos with [tipo-vehiculo = \"furgoneta\"]"

PLOT
1374
302
1619
545
edad media
NIL
NIL
0.0
0.0
0.0
20.5
true
false
"" ""
PENS
"edad_media" 1.0 0 -16777216 true "" "plot edad-media-vehiculos"

SLIDER
37
273
209
306
pprecio
pprecio
0
3
1.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

Este modelo simula la evolución de la flota de vehículos en una población de 100 personas durante varias décadas (desde 2024 en adelante), con especial atención a la transición hacia vehículos eléctricos y la reducción de emisiones de CO₂.

El modelo intenta responder preguntas del tipo:
- ¿Cómo de rápido puede cambiar la flota hacia vehículos eléctricos bajo diferentes condiciones económicas y de preferencias?
- ¿Qué impacto tiene la antigüedad obligatoria de reemplazo (20 años) y la prohibición de vehículos de combustión en 2055?
- ¿Cómo evolucionan la edad media de los vehículos y las emisiones acumuladas de CO₂?


## HOW IT WORKS

- Hay 100 personas, cada una propietaria de un vehículo.
- Cada vehículo tiene: tipo (turismo, furgoneta, camión), motor (eléctrico, híbrido enchufable, combustión), consumo, emisiones por 100 km, edad y tamaño.
- Cada persona tiene: nivel de ahorro (50, 400 o 1500 €/mes), preferencia por eléctrico o combustión (motorHead = 0 o 1), y kilómetros que recorre al año (implícito en ciudad/carretera, aunque no se usa activamente aún).

Reglas principales:
1. Cada año (cada 12 ticks), ~1% de las personas intentan comprar un vehículo nuevo o de segunda mano.
2. Si el vehículo tiene 20 años o más → la persona **siempre** intenta reemplazarlo (obligatorio).
3. La decisión de compra depende de:
   - Preferencia (motorHead)
   - Ahorro disponible (ahorro mensual + ahorro por combustible + achatarramiento)
   - Precio del vehículo nuevo o de segunda mano
   - Año actual (híbridos solo hasta 2035, eléctricos forzados a partir de 2055)
4. En 2055 todos los vehículos de combustión se convierten automáticamente a eléctricos.
5. Cada mes se calcula:
   - Envejecimiento de vehículos
   - Emisiones mensuales (basadas en 800 km/mes por defecto)
   - Edad media de la flota
   - CO₂ acumulado total (en toneladas)

## HOW TO USE IT

1. Presiona SETUP para inicializar la simulación.
2. Presiona GO para ejecutar (o GO ONCE para avanzar un tick/mes).
3. Observa los monitores recomendados:
   - Edad media vehículos → edad-media-vehiculos
   - CO₂ acumulado (toneladas) → precision co2-acumulado 1
   - Número de vehículos eléctricos → count vehiculos with [tipo-motor = "electrico"]
   - Vehículos totales → count vehiculos
4. Los vehículos se mueven hacia la derecha para visualización (solo estético).
5. Los colores indican el tipo de motor:
   - Verde lima → eléctrico
   - Amarillo → híbrido enchufable
   - Rojo → combustión

## THINGS TO NOTICE

- Al principio casi no hay cambios (muy pocos vehículos se reemplazan).
- A partir del año ~2044–2045 comienzan a aparecer más cambios por vehículos que cumplen 20 años.
- En 2055 se produce un cambio masivo: todos los vehículos de combustión pasan a eléctricos.
- La edad media de la flota tiende a mantenerse baja cuando hay muchos reemplazos obligatorios.
- Las emisiones de CO₂ crecen lentamente al principio y luego se estabilizan o incluso disminuyen después de 2055 (dependiendo del mix eléctrico).

## THINGS TO TRY

- Cambia el valor de km-por-mes (en el procedimiento go) y observa cómo afecta al CO₂ acumulado.
- Aumenta achatarramiento-base (en globals o setup) a 3000–5000 → verás más reemplazos tempranos.
- Baja divisor-pago a 180 o 120 → facilita la compra de vehículos nuevos → transición más rápida.
- Sube PPRECIO a 1.3–1.5 → hace más difícil comprar vehículos nuevos → más segunda mano y más vehículos viejos.
- Cambia el porcentaje de candidatas (en go) de 0.01 a 0.03 o 0.05 → más dinámica pero menos realista.
- Observa qué pasa si eliminas la regla de 2055 (comenta el if año >= 2055).

## EXTENDING THE MODEL

Posibles mejoras y extensiones:

- Añadir variable km-anuales-por-tipo-de-vía (ciudad vs carretera) y consumo realista según uso.
- Incluir coste de mantenimiento y batería (depreciación más rápida en eléctricos).
- Modelar evolución del precio de baterías y del mix eléctrico (mix más limpio con los años).
- Añadir incentivos públicos variables por año (subvenciones a eléctricos).
- Incluir chatarrería obligatoria a 15 años en lugar de 20 (normativa europea más estricta).
- Añadir emisiones en fabricación (huella de carbono inicial del vehículo).
- Modelar segunda mano con precio decreciente según edad y tipo de motor.
- Incluir averías o probabilidad de fallo en función de la edad.

## NETLOGO FEATURES

- Uso de turtle-set para combinar conjuntos de agentes sin duplicados (candidatas + obligadas).
- precision para redondear la edad media a 2 decimales.
- ifelse-value para asignar colores según tipo-motor.
- member? para comprobar tipos de vehículo en una lista.
- sum [...] of para calcular totales agregados (edad y emisiones).
- Uso de factor de conversión a toneladas en las emisiones.

## RELATED MODELS

Modelos relacionados en la biblioteca de NetLogo o en línea:

- Traffic Basic / Traffic 2 Lanes (transporte y flujo)
- Climate Change models (emisiones y políticas climáticas)
- Electric Vehicle Adoption (modelos de difusión de tecnología)
- Energy and Environment suite

## CREDITS AND REFERENCES

Creado a partir de conversaciones y refinamientos iterativos en 2025–2026.

No tiene URL pública oficial (es un modelo personalizado).

Conceptos inspirados en:
- Modelos de transición energética (IEA, T&E, proyectos europeos Fit for 55)
- Estudios de vida útil media de vehículos en Europa (~14–18 años)
- Prohibición de venta de vehículos de combustión en 2035 (UE) y circulación en 2050–2060
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
