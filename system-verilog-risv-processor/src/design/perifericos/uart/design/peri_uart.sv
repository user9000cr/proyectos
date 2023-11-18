`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Institucion: Instituto Tecnologico de Costa Rica 
// Curso: Taller de Dise�o Digital
// Grupo: 1
// 
// Nombre del m�dulo: top_uart
// Descripci�n: Modulo top para el UART
//    
// Dependencias: reg_data_uart.sv, reg_ctrl_uart.sv, fsm_uart.sv, UART_TX_CTRL.vhd
// 
//////////////////////////////////////////////////////////////////////////////////

module peri_uart (
    input    logic              clk_i,                // Entrada de clock de 10MHz
    input    logic              reset_i,              // Entrada de reset del bloque top del uart
    input    logic  [ 31 : 0 ]  data_i,               // Entrada de datos que se cargan al registro de datos que se van a transmitir
    input    logic              we_ctrl_uart_i,       // Write-enable que activa el registro de control 
    input    logic              we_data_uart_i,       // Write-enable que activa el registro de datos 
    output   logic              uart_tx_o,            // Salida de datos enviados por el bloque uart
    output   logic  [ 31 : 0 ]  data_out_ctrl_o);

    logic              bit_send;
    logic              bit_ready;
    logic  [ 7  : 0 ]  data_inter;
    logic              bit_we;
    logic              data_out_control;
    
    assign data_out_ctrl_o = {31'b0, data_out_control};
    

// Instancia del registro de datos del UART
    reg_data_uart data_uart(
        .clk_i             (clk_i),              // Se�al de entrada clock de 10MHz 
        .rst_i             (reset_i),            // Se�al de reset general del sistema
        .data_i            (data_i[7:0]),        // Entrada de datos de 8 bits, los cuales se van a transmitir por el uart
        .we_data_uart_i    (we_data_uart_i),     // Se�al de write enable del registro de datos que env�a el uart
        .data_o            (data_inter));  

// Instancia del registro de control del UART
    reg_ctrl_uart ctrl_uart(
        .clk_i             (clk_i),              // Se�al de reloj de 10MHz
        .reset_i           (reset_i),            // Se�al de reset 
        .d_1_i             (data_i[0]),          // Se�al 1 de entrada de dato
        .d_2_i             (1'b0),               // Se�al 1 de entrada de 
        .we_1_i            (we_ctrl_uart_i),     // Se�al de write enable 1
        .we_2_i            (bit_we),             // Se�al de write enable 2
        .q_o               (data_out_control));  // Se�al de salida de dato

    
// Instancia de la maquina de estados del UART
    fsm_uart uart_fsm(
        .clk_i             (clk_i),              // Entrada de reloj de 10MHz para la m�quina de estados
        .rst_i             (reset_i),            // Entrada de reset de la m�quina de estados
        .in_i              (data_out_control),   // Bit in que inicia hace que el bit de send se envie al bloque uart
        .ready_i           (bit_ready),          // Bit de ready el cual indica cuando la transacci�n est� completada
        .we_o              (bit_we),             // Bit de write-enable que hace que se escriba un 0 en el registro de control 
        .send_o            (bit_send));          // Bit de send que inicia la transmisi�n de uart

// Instancia del bloque UART
    UART_TX_CTRL uart(
        .SEND              (bit_send),           // Bit de send el cual inicia la transmisi�n 
        .DATA              (data_inter),         // Entrada de datos que se desean transmitir por medio de uart
        .CLK               (clk_i),              // Entrada de reloj de 10MHz para la m�quina de estados
        .READY             (bit_ready),          // Bit ready el cual indica cuando se termin� la transacci�n
        .UART_TX           (uart_tx_o));         // Bit que realiza la transmision, se envia el dato de forma serial

endmodule