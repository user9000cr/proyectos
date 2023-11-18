`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Institucion: Instituto Tecnologico de Costa Rica 
// Curso: Taller de Dise�o Digital
// Grupo: 1
// 
// Module Name: reg_teclado
// Descripcion: Registro para activar la comunicacion con el teclado
//    
// Dependencias: 
// 
//////////////////////////////////////////////////////////////////////////////////

module reg_teclado (
    input    logic                clk_i,       // Se�al de reloj de 10MHz
    input    logic                reset_i,     // Se�al de reset 
    input    logic    [ 31 : 0 ]  data_in1_i,  // Se�al 1 de entrada de dato
    input    logic    [ 31 : 0 ]  data_in2_i,  // Se�al 2 para entrada de dato
    input    logic                we_1_i,      // Se�al de write enable 1 proveniente de bloque control de buses
    input    logic                we_2_i,      // Se�al de write enable 2 proveniente del basic_ps2_keybord
    output   logic    [ 31 : 0 ]  rs1_o);      // Se�al de salida de dato

    logic  rst;

    assign rst = ~reset_i;

// Se implementa la logica para el registro, escribe si tiene write enable
    always_ff @(posedge clk_i) begin        
        if      (!rst)    rs1_o   <= 0;
        
        if      (we_2_i)  rs1_o   <= data_in2_i;
        
        else if (we_1_i)  rs1_o   <= data_in1_i;
    end
    
endmodule
