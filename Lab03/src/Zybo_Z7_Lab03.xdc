## ====================================================================
## Archivo de Restricciones (XDC) - Laboratorio 03 (Zybo Z7)
## ====================================================================

## 1. Reloj del sistema de 125 MHz (sysclk)
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }];

## 2. Reset (Opcional, en Pmod JD pin 2 - P14 con PULLDOWN para que sea 0 por defecto)
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports { reset }];

## 3. Switches (SW[3:0])
## SW[3:0]: Dato para escribir en registros. SW[2:0]: Seleccion de operacion ALU
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { sw[0] }];
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { sw[1] }];
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { sw[2] }];
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { sw[3] }];

## 4. Pulsadores (BTN[3:0])
## BTN0: Seleccionar registro de escritura (R0-R3)
## BTN1: Escribir dato en registro seleccionado
## BTN2: Cambiar combinacion de operandos
## BTN3: Ejecutar ALU y actualizar display
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { btn[0] }];
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { btn[1] }];
set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33 } [get_ports { btn[2] }];
set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports { btn[3] }];

## 5. LEDs individuales (LED0 - LED3) -> Registros activos en la operacion
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { led[0] }];
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { led[1] }];
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { led[2] }];
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { led[3] }];

## 6. LED RGB 6 (Indicador de registro de escritura seleccionado)
## rgb_led[0] = Azul (M17), rgb_led[1] = Verde (F17), rgb_led[2] = Rojo (V16)
set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33 } [get_ports { rgb_led[0] }];
set_property -dict { PACKAGE_PIN F17   IOSTANDARD LVCMOS33 } [get_ports { rgb_led[1] }];
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { rgb_led[2] }];

## 7. Display TM1637 en Pmod Header JC
## jc[0] (Pin 1) -> CLK
## jc[1] (Pin 2) -> DIO (SDA bidireccional con PULLUP)
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { tm1637_clk }];
set_property -dict { PACKAGE_PIN W15   IOSTANDARD LVCMOS33 PULLUP true } [get_ports { tm1637_dio }];
