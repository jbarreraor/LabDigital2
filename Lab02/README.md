# Laboratorio 02  
## Lab02: Diseño, simulación e implementación de una ALU de 4 bits

---

## Integrantes

- Juan Sebastián Florez Payares
- Juan Esteban Barrera Ortiz
- Carlos Andrés Herrera Molina
- Luciano Manrique Medina

**Grupo de trabajo: 3**  
**Semestre:** 2026-1  

---

## Índice

- [Diseño implementado](#diseño-implementado)
- [Operaciones implementadas](#operaciones-implementadas)
- [Almacenamiento de operandos y código de operación](#almacenamiento-de-operandos-y-código-de-operación)
- [Indicador LED RGB](#indicador-led-rgb)
- [Simulaciones](#simulaciones)
- [Implementación en FPGA](#implementación-en-fpga)
- [Conclusiones](#conclusiones)
- [Referencias](#referencias)

---

## Diseño implementado

En esta sección se presenta el funcionamiento general de la ALU de 4 bits, 
la arquitectura propuesta y los módulos desarrollados.

---

## Operaciones implementadas

En esta sección se presentan las operaciones aritméticas y lógicas implementadas
en la ALU y sus respectivos códigos de operación.

---

## Almacenamiento de operandos y código de operación

En esta sección se explica cómo se ingresan y almacenan los operandos A y B,
así como la forma en que se conserva el código de operación seleccionado.

---

## Identificación de operaciones mediante LED RGB

Para facilitar la identificación de la operación seleccionada en la ALU, se utiliza un LED RGB de la FPGA. El color mostrado depende del código de operación almacenado en el registro `op[1:0]`. De esta forma, es posible identificar visualmente qué operación está ejecutando la ALU antes de observar el resultado en los LEDs de salida.

| Código `op[1:0]` | Operación | Salida `rgb[2:0]` | Color |
|:---:|:---:|:---:|:---:|
| `00` | Suma  | `010` | Verde |
| `01` | Resta | `100` | Rojo |
| `10` | AND   | `101` | Morado |
| `11` | OR    | `110` | Amarillo |

La selección del color se realiza en el módulo principal mediante una estructura `case`, relacionando cada código de operación con una combinación específica de las tres componentes del LED RGB. Esto permite utilizar el LED como un indicador visual del estado actual de la ALU.

---

## Simulaciones

Para verificar el funcionamiento de la ALU se desarrolló un testbench en el archivo `tb_alu.v`, en el cual se probaron las cuatro operaciones implementadas: suma, resta, AND y OR. Durante la simulación se modificaron los operandos `a` y `b` junto con el código de operación `op`, observando el resultado obtenido en la señal `out`.

Las señales utilizadas para verificar el comportamiento fueron:

- `a[3:0]`: primer operando de 4 bits.
- `b[3:0]`: segundo operando de 4 bits.
- `op[1:0]`: código utilizado para seleccionar la operación.
- `out[3:0]`: resultado de 4 bits generado por la ALU.

La simulación fue realizada con **Icarus Verilog** y las señales obtenidas fueron visualizadas mediante **GTKWave** en formato decimal.

### Evidencia GTKWave

![Simulación de la ALU](sim/img/simulacion_alu.png)

En la simulación se observa inicialmente la operación de suma (`op = 0`). Para valores dentro del rango de 4 bits se obtiene directamente el resultado esperado, como `3 + 4 = 7`. También se verificaron casos de desbordamiento, como `9 + 8 = 17`, donde la salida observada es `1`, debido a que `out` tiene únicamente 4 bits y no almacena el acarreo de salida.

Posteriormente, con `op = 1`, se verifica la resta. El diseño obtiene la diferencia entre los operandos sin producir resultados negativos. Por ejemplo, tanto `9 - 4` como la combinación inversa con `4` y `9` producen una salida igual a `5`. Cuando ambos operandos son iguales, la salida obtenida es `0`.

Para `op = 2` se comprueba la operación lógica AND bit a bit. Por ejemplo, utilizando `a = 12` y `b = 10` se obtiene `out = 8`, correspondiente a la operación binaria `1100 AND 1010 = 1000`.

Con `op = 3` se verifica la operación lógica OR. Para los mismos operandos, `a = 12` y `b = 10`, se obtiene `out = 14`, correspondiente a `1100 OR 1010 = 1110`.

Finalmente, al final de la simulación se mantienen constantes los operandos `a = 12` y `b = 5` mientras se modifica únicamente el código `op`. Los resultados obtenidos son:

| `op` | Operación | Resultado observado |
|:---:|:---:|:---:|
| `0` | Suma | `1` |
| `1` | Resta | `7` |
| `2` | AND | `4` |
| `3` | OR | `13` |

Esta última prueba permite comprobar que el código de operación selecciona correctamente cada una de las funciones de la ALU manteniendo los mismos operandos de entrada. En conjunto, los resultados observados coinciden con el comportamiento esperado para las cuatro operaciones implementadas.
---

## Implementación en FPGA

El diseño fue implementado físicamente en la tarjeta **Zybo Z7**, utilizando los switches y pulsadores disponibles en la FPGA para ingresar los operandos y seleccionar la operación. Los cuatro switches permiten establecer valores binarios de 4 bits, mientras que los pulsadores permiten almacenar los operandos `A` y `B` y configurar el código de operación.

Una vez almacenados los operandos y seleccionada la operación, la ALU realiza el cálculo de forma combinacional. El resultado de 4 bits se muestra mediante los LEDs de la tarjeta, mientras que el LED RGB permite identificar visualmente la operación seleccionada de acuerdo con la tabla definida anteriormente.

Para evitar que los rebotes mecánicos de los pulsadores generen múltiples registros durante una sola pulsación, las entradas de los botones pasan por un módulo de antirrebote antes de ser utilizadas para almacenar los datos.

### Evidencia

A continuación se presenta un video del funcionamiento del diseño implementado físicamente en la tarjeta **Zybo Z7**. En este se observa el ingreso y almacenamiento de los operandos mediante los switches y pulsadores, la selección de las diferentes operaciones de la ALU, la visualización del resultado mediante los LEDs y el cambio de color del LED RGB de acuerdo con la operación seleccionada.


---

## Conclusiones

- Principales aprendizajes del laboratorio.
- Dificultades encontradas durante el desarrollo.
- Importancia de la simulación y verificación antes de la implementación física.

---

## Referencias
