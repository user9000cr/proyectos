`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Institucion: Instituto Tecnologico de Costa Rica 
// Curso: Taller de Dise�o Digital
// Grupo: 1
// 
// Module Name: reg_leds
// Descripcion: registro del periferico de los leds
//    
// Dependencias: 
// 
//////////////////////////////////////////////////////////////////////////////////

module reg_leds (
    input    logic              clk_i,                  // Se�al de reloj de 10MHz
    input    logic              reset_i,                // Se�al de reset 
    input    logic  [ 15 : 0 ]  data_in_i,              // Se�al de entrada de dato
    input    logic              we_led_i,               // Se�al de write enable 
    output   logic  [ 15 : 0 ]  salida_reg_leds_o);     // Se�al de salida del registro

    logic  rst;
    logic  we;

    assign rst = ~reset_i;
    assign we = ~we_led_i;

// Se implementa la logica para el registro, escribe si tiene write enable
    always_ff @(posedge clk_i) begin        
    
        if  (!rst)    salida_reg_leds_o <= 0;
        
        if (!we)  salida_reg_leds_o <= data_in_i;
    end
    
endmodule
