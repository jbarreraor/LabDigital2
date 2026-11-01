# Laboratorio 03
## Lab03: ALU + Banco de Registros + Diseño Modular

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

- [Descripción del sistema](#descripción-del-sistema)
- [Arquitectura modular](#arquitectura-modular)
- [Interfaz de usuario](#interfaz-de-usuario)
- [Estrategia de visualización](#estrategia-de-visualización)
- [Simulaciones](#simulaciones)
- [Implementación en FPGA](#implementación-en-fpga)
- [Análisis de resultados](#análisis-de-resultados)
- [Conclusiones](#conclusiones)
- [Referencias](#referencias)

---

## Descripción del sistema

## Arquitectura modular

### Diagrama de bloques

### Explicación de los módulos

#### `alu.v`
#### `reg_bank.v`
#### `comb_selector.v`
#### `display_tm1637.v`
#### `top.v`

## Interfaz de usuario

### Switches
### Botones
### LEDs
### LED RGB
### Display TM1637

## Estrategia de visualización
El sistema de visualización se divide en 3 partes: display de 7 segmentos de 4 bits, LEDs monocromáticos y LED RGB.

Para el RGB, se le asignó como función visualizar el registro que se está utilizando, ya sea para escribir o para guardar un byte en ese registro. Así, se asigna la siguiente tabla de colores:

| Color del LED | Registro seleccionado |
|---|---|
| Azul | Registro 1 |
| Verde | Registro 2 |
| Rojo | Registro 3 |
| Cian | Registro 4 |

Recordar que el cambio de registro se realiza con el botón asignado número 2.

Para los LEDs monocromáticos que se ubican arriba de los switches de selección, se les asignó la función de mostrar qué registros se están operando. Por ejemplo, si se encienden los dos primeros LEDs de derecha a izquierda, se estarán operando los registros 0 y 1. Ahora, como se implementan operaciones en las cuales importa el orden de selección de los registros, si se vuelve a presionar el botón que alterna entre registros, este hará un barrido de todas las combinaciones entre registros posibles. Es decir, la primera vez que se vean encendidos los dos LEDs antes mencionados se hará la siguiente operación: «Registro 1 operación seleccionada Registro 2». Entonces, la segunda vez que estos LEDs sean encendidos, se estará realizando la operación en orden inverso de los registros: «Registro 2 operación seleccionada Registro 1».

Finalmente, el display de 7 segmentos de 4 bits presentará el resultado de la operación y los registros seleccionados. Este resultado se presenta en decimal; los números negativos provenientes de la resta se mostrarán con el signo menos en el bit anterior al resultado.

Ejemplo: si operamos el registro 1 = 10 y el registro 2 = 5 como resta, el display mostraría el siguiente resultado:

| Bit 1 | Bit 2 | Bit 3 | Bit 4 |
|---|---|---|---|
| OFF | OFF | OFF | 5 |

Ahora, si operamos el registro 2 = 5 y el registro 1 = 10 como resta, el display mostraría el siguiente resultado:

| Bit 1 | Bit 2 | Bit 3 | Bit 4 |
|---|---|---|---|
| OFF | OFF | - | 5 |


## Simulaciones

### Testbench
### Evidencia GTKWave

## Implementación en FPGA

### Evidencia

## Análisis de resultados

## Conclusiones

## Referencias
