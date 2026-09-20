# Laboratorio 00  
## Introducción a Verilog, Simulación y Máquinas de Estados Finitos (FSM)

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
- [Laboratorio 00](#laboratorio-00)
  - [Introducción a Verilog, Simulación y Máquinas de Estados Finitos (FSM)](#introducción-a-verilog-simulación-y-máquinas-de-estados-finitos-fsm)
  - [Integrantes](#integrantes)
  - [Índice](#índice)
  - [Ejercicio 1: FSM de control – Semáforo simple](#ejercicio-1-fsm-de-control--semáforo-simple)
    - [Diseño implementado](#diseño-implementado)
    - [Simulación](#simulación)
      - [Evidencias](#evidencias)
    - [Conclusiones](#conclusiones)

---

## Ejercicio 1: FSM de control – Semáforo simple

### Diseño implementado

El objetivo era diseñar un semáforo vehicular que cambiara de estados de la forma verde-amarillo-rojo y luego rojo-amarillo-verde, dándole a cada estado una duración de ciclos de reloj definida.

Para este ejercicio se escogió diseñar una Maquino de Estados Finitos (FSM) de arquitectura Moore. Primero se planteó el diagrama de estados según las reglas del ejercicio:

* Solo una salida puede estar activa a la vez.
* El sistema inicia siempre en el estado **Verde** después de un reset.
* La transición entre estados ocurre automáticamente al cumplirse el número de ciclos asignado.

![alt](img/FSM_semaforo.png)


Donde los estados definidos y su duración fueron los siguientes:

- S0: Luz verde - 5 ciclos
- S1: Luz amarilla - 2 ciclos
- S2: Luz roja - 4 ciclos

Como son 3 estados, definimos el número de bits necesarios para representarlos usando $2^n \geq 3$, entonces el número de bits necesarios es $n = 2$. Con esto se tiene a $Q_1$ y $Q_0$ como los bits de estados.

| Q1 | Q0 | Estado Siguiente |
| :---: | :---: | :---: |
| 0 | 0 | S0 |
| 0 | 1 | S1 |
| 1 | 0 | S2 |
| 1 | 1 | X |



En [semaforo.v](./Ejercicio1_FSM_Semaforo_Simple/semaforo.v) se describe el funcionamiento completo de este sistema. En general lo que se hizo fue definir las entradas como lo muestra la tabla de arriba, y como salida se definió un vector de dos bits llamado ```luz```.

```
module semaforo(
    input clk,
    input reset,
    output reg [1:0] luz
);
```

También se asignaron los nombres a los estados.

```
localparam verde    = 2'b00;
localparam amarillo = 2'b01;
localparam rojo     = 2'b10;
```

De igual manera, se declararon 2 registros: ```cont``` con el fin de llevar la cuenta de los ciclos de reloj y ```state``` con el objetivo de guardar el estado actual del semáforo.

```
reg [3:0] cont;
reg [1:0] state;
```

Con esto más adelante pudimos definir correctamente el cambio de estado según los ciclos de reloj. 

Luego, se creó la lógica secuencia usando un bloque ```always @(posedge clk) begin``` que se ejecuta cada vez que clk tenga un flanco positivo.

Dentro de este bloque, primero se tuvo en cuenta el reset, donde en caso de activarse, el sistema vuelve a su estado inicial, que es verde, y además se reinicia el contador.

```
if (reset) begin
    state <= verde;
    cont  <= 1;
end
```

si no se activa el reset entonces el contador empieza a funcionar.

```
else begin
    cont <= cont + 1;
```

En este momento es donde se usaron condicionales que compararan el ciclo de reloj con el número de ciclos de duración de cada estado. Por ejemplo para el caso de Verde se tiene:

```
if (cont < 5) begin
    state <= verde;
end
```
y la misma lógica para el resto de estados.

```
else if (cont == 5) begin
  state <= amarillo;
end
else if (cont == 7) begin
  state <= rojo;
end
else if (cont == 11) begin
  state <= amarillo;
end
else if (cont == 13) begin
  state <= verde;
  cont<=1;
end
```

Donde se cumple la secuencia de un semáforo simple verde-amarillo-rojo-amarillo-verde.

Luego, definimos otro bloque ```always```donde simplemente asignamos el estado actual a ```luz```

```
always @(*) begin
    luz = state;
end
```
---
### Simulación

Para la simulación de [semaforo.v](./Ejercicio1_FSM_Semaforo_Simple/tb_semaforo.v) creamos un modulo ```tb_semaforo``` y le decimos las señales que vamos a modificar, que son el clock y el reset; mientras que la salida va a ser el vector ```luz```.

```
module tb_semaforo;
  reg clk, reset;
  wire [1:0] luz;
```
Luego creamos un dispositivo bajo prueba (dut) que es el que conecta las entradas y salida del testbench con el semáforo.


```
semaforo dut (
    .clk(clk),
    .reset(reset),
    .luz(luz)
  );
```

Después generamos un ciclo de reloj donde cada flanco dure $5ns$, por lo que su periodo es de $10ns$. Y además lo negamos para que empiece en el flanco positivo.

```
always #5 clk = ~clk;
```

Antes de simular, configuramos para que el clock empiece en cero, el reset empiece en activo, y el tiempo de simulación sea de $400ns$.

```
initial begin
  $dumpfile("semaforo.vcd");
  $dumpvars(0, tb_semaforo);

  clk   = 0;
  reset = 1;
  #12 reset = 0;
  #400 $finish; 
end
```

En [tb_semaforo.v](./Ejercicio1_FSM_Semaforo_Simple/tb_semaforo.v) se describe el funcionamiento completo del testbench.


#### Evidencias 
A continuación se muestran las señales de entrada, salida y clock leídas con GTKWave.
![alt](img/semaforo_gtk.png)

Dentro de las señales observadas tenemos la de ```luz``` que es la que representa al semáforo, también observamos las señales de los colores con el fin de comparar si la secuencia es la correcta.

Podemos ver que el ```cont``` se activa en cada flanco positivo de ```clk```. También que el contador va de $1$ hasta $13$ debido a que en ese valor el contador se reinicia. Además, se puede observar un "delay" en los vectores de ```luz``` y ```cont``` debido justamente a que el primer flanco positivo empieza en $5ns$.

Finalmente verificando la señal ```luz``` confirmamos que la secuencia es la deseada: después del reset se activa el verde que se mantiene durante 5 ciclos del clk, luego se activa el amarillo que tiene una duración de 2 ciclos y luego durante 4 ciclos más se activa el rojo, para después pasar a amarillo por 2 ciclos y a verde por 5 ciclos más, y repetir esta secuencia.

---
### Conclusiones

- Se logró diseñar e implementar una FSM de Moore para controlar por ciclos las luces de un semáforo simple y seguir la secuencia verde-amarillo-rojo-amarillo-verde.
- Se aprendió que ``` always @(posedge clk)``` se usa para realizar cambios de estado sincronizados al clock.
- Se implementó un testbench correctamente con el que se pudo verificar el correcto funcionamiento de sistema. También se resalta su importancia ya que este tipo de simulaciones permiten detectar errores y corregirlos antes de alguna implementación física.





