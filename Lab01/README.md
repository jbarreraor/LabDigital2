# Laboratorio 01  
## Lab01: FPGA (Zybo Z7), Vivado/Vitis y Validación de Hardware

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

- [Laboratorio 01](#laboratorio-01)
  - [Lab01: FPGA (Zybo Z7), Vivado/Vitis y Validación de Hardware](#lab01-fpga-zybo-z7-vivadovitis-y-validación-de-hardware)
  - [Integrantes](#integrantes)
  - [Índice](#índice)
  - [Ejercicio 1: Verificación Del Entorno En FPGA (Smoke Test)](#ejercicio-1-verificación-del-entorno-en-fpga-smoke-test)
  - [Ejercicio 2: Test Funcional Personalizado (Diseño libre)](#ejercicio-2-test-funcional-personalizado-diseño-libre)
    - [Diseño implementado](#diseño-implementado)
    - [¿Por qué no usamos los pulsadores que están en la FPGA?](#por-qué-no-usamos-los-pulsadores-que-están-en-la-fpga)
    - [Simulaciones](#simulaciones)
    - [Restricciones de pines (XDC)](#restricciones-de-pines-xdc)
    - [Evidencias](#evidencias)
  - [Conclusiones](#conclusiones)
  - [Referencias](#referencias)

---


## Ejercicio 1: Verificación Del Entorno En FPGA (Smoke Test)


## Ejercicio 2: Test Funcional Personalizado (Diseño libre)

### Diseño implementado

Para este ejercicio, se diseñó un sistema combinacional que consistió en realizar operaciones de `AND` y `OR` haciendo uso de pulsadores físicos de la FPGA Zybo Z7. Para esto se usaron 4 switches, 4 botones pulsadores de la FPGA, 2 switches a parte conectados a una protoboard y 5 leds RGB integrados en la placa Zybon 7z para indicar el resultado de cada operación y el estado actual de activación.

La lógica detrás de este diseño se explica en la siguiente tabla:

| Modo | Condición | y | led |
| :--- | :--- | :--- | :--- |
| AND | `andd=1, orr=0` | `a & sw` | `001` (azul) |
| OR | `andd=0, orr=1` | `a \| sw` | `010` (verde) |
| OFF | ninguno o ambos | `0000` | `100` (rojo) |

Donde `andd` y `orr` son los bits encargados de definir cada uno de los casos, y también el color del led RGB.

Es importante resaltar que los nombres `andd` y `orr` fueron escritos de esa manera debido que las palabras `and` y `or` son reservadas para la lógica de verilog.

---
### ¿Por qué no usamos los pulsadores que están en la FPGA?

PONGA LA EXPLICACIÓN ACÁ

---

De esta manera, se declararon las entradas, las salidas y un registro de estado actual.

```
input clk,
input andd,
input orr,
input reset,
input [3:0] a,
input [3:0] sw,
output reg [2:0] led,   // LED RGB: led[2]=Rojo, led[1]=Verde, led[0]=Azul
output reg [3:0] y      // 4 LEDs de resultado
);

// Estados: 00 = apagado/invalido, 01 = OR, 10 = AND
localparam OFF_ST = 2'b00;
localparam OR_ST  = 2'b01;
localparam AND_ST = 2'b10;

reg [1:0] state = OFF_ST;
```

Luego se describió un bloque secuencial donde se definió que en caso de que el reset esté activado, entonces `state <= OFF_ST` sin esperar el reloj; y si no, se evalúa el estado de `{andd, orr}` y se cambia de estado según eso. De esta manera se aclara también que los estados siguientes no dependen de los actuales, solo de las entrada.

```
always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= OFF_ST;
    end
    else begin
        case ({andd, orr})
            2'b10:   state <= AND_ST;  // solo andd presionado
            2'b01:   state <= OR_ST;   // solo orr presionado
            default: state <= OFF_ST;  // 2'b11 (ambos) o 2'b00 (ninguno)
        endcase
    end
end
```

Para terminar con la lógica, se implementó un bloque combinacional para asignar el estado a la salida `y` e indicar el color del led de la operación en `led`.


```
always @(*) begin
    case (state)
        AND_ST: begin
            y   = a & sw;
            led = 3'b001; // Azul
        end
        OR_ST: begin
            y   = a | sw;
            led = 3'b010; // Verde
        end
        default: begin // OFF_ST
            y   = 4'b0000;
            led = 3'b100; // Rojo
        end
    endcase
end
```


---

### Simulaciones

Luego, se generó un testbench donde primero se parte en el estado **OFF** por efecto del reset, con `y` en cero. Donde los selectores `andd` y `orr` determinan el modo: `orr` activa la operación OR, `andd` activa la AND, y cualquier otra combinación (ninguno o ambos) devuelve el sistema a OFF.

Después, el cambio de modo ocurre de forma síncrona, o sea, en el siguiente flanco de subida del reloj, mientras que la salida `y` responde de inmediato a los cambios de los operandos `a` y `sw`, sin esperar al reloj.

Cabe resaltar que el reset es asíncrono, o sea que lleva el sistema a OFF en cuanto se activa, y al soltarlo la máquina retoma el modo indicado por los selectores en el siguiente flanco de reloj. 

Finalmente en la simulación se recorre estos casos en orden: reset, OR, AND, entrada inválida, reset asíncrono; y termina con un barrido de operandos en modo AND para comprobar que `y` siempre sigue el resultado esperado. La salida de ***GTKwave*** se muestra a continuación:


![alt](img/salida_simu_gtk.jpeg)

### Restricciones de pines (XDC)

En [Zybo-Z7_IMPANDOR_actualizado.xdc](src/Zybo-Z7_IMPANDOR_actualizado.xdc) se asignaron los pines de la placa Zybo Z7 y la definición del clock. A continuación en la tabla mostramos un resumen de este proceso:

| Puerto | Pines FPGA | Recurso en la placa |
|---|---|---|
| `clk` | K17 | Reloj del sistema (125 MHz) |
| `a[3:0]` | G15, P15, W13, T16 | Interruptores SW0–SW3 |
| `sw[3:0]` | K18, P16, K19, Y16 | Pulsadores BTN0–BTN3 |
| `andd` | T14 | Pmod JD |
| `orr` | T15 | Pmod JD |
| `reset` | P14 | Pmod JD |
| `y[3:0]` | M14, M15, G14, D18 | LEDs LD0–LD3 |
| `led[2:0]` | V16, F17, M17 | LED RGB LED6 |

Para la implementación física se usó un circuito con resistencia pull up activado por un switch de dos bits. las conexiones se hicieron con base en este esquema.

![Diagrama de conexiones y recursos de la placa Zybo Z7](img/pines_fpgs_Z7.png)

**Fig. 1.** Diagrama de conexiones y recursos de la placa Zybo Z7. Tomado de [1].

***Coloque los pines que se usaron si en la tabla no están***


### Evidencias

A continuación se observa un video con el diseño implementado durante la clase de laboratorio.

**ACÁ ponga el video** 


---

## Conclusiones

- Moraleja

---

## Referencias

[1] Digilent, “Zybo Z7 Reference Manual,” Digilent Inc. [En línea]. Disponible en: https://digilent.com/reference/programmable-logic/zybo-z7/reference-manual.

