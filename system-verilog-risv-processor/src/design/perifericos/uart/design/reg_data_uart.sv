`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Institucion: Instituto Tecnologico de Costa Rica 
// Curso: Taller de Dise�o Digital
// Grupo: 1
// 
// Nombre del m�dulo: reg_data_uart
// Descripci�n: Registro de datos para el UART
//    
// Dependencias: 
// 
//////////////////////////////////////////////////////////////////////////////////

module reg_data_uart(
    input                      clk_i,            // Se�al de entrada clock de 10MHz 
    input                      rst_i,            // Se�al de reset general del sistema
    input    logic  [ 7 : 0 ]  data_i,           // Entrada de datos de 8 bits, los cuales se van a transmitir por el uart
    input    logic             we_data_uart_i,   // Se�al de write enable del registro de datos que env�a el uart
    output   logic  [ 7 : 0 ]  data_o);          // Se�al de salida de los datos de 8 bits que se van hacia el bloque uart

    logic   rst;
    assign  rst = ~rst_i;

// Se implementa la logica de un registro, escribe si tiene la se�al de write enable
    always_ff @(posedge clk_i) begin
        if(!rst)              data_o <= 8'b0;

        if(we_data_uart_i)    data_o <= data_i;
    end
    
endmodule