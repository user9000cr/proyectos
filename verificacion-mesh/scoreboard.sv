//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Scoreboard: Este objeto se encarga de llevar un estado del comportamiento de la prueba y es capa de generar reportes //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class scoreboard #(parameter pckg_sz   = 25,
                   parameter fifo_dpth = 8);

    //Variables declaration
    int  tamano_scb                 = 0;
    int  file;
    int  bw_file;
    int  csv_size                   = 0;
    int  transacciones_completadas  = 0;
    int  conteo;
    int  retardo_total              = 0;
    bit  file_inicializado          = 0;
    real min_bw                     = 1000;
    real max_bw                     = 0;
    real avg_bw                     = 0;
    real tot_bw                     = 0;
    shortreal retardo_promedio;
    event reporte_gen;
  
  	// Elements required for generating the pkg path
  	mesh44 mesh;

    // Mailboxes declaration
    trans_mbx #(.pckg_sz(pckg_sz)) mbx_agt_scb;   // Agent -> Scoreboard
    trans_mbx #(.pckg_sz(pckg_sz)) mbx_scb_chk;   // Scoreboard -> Checker
    trans_mbx #(.pckg_sz(pckg_sz)) mbx_chk_scb;   // Checker -> Scoreboard
    trans_mbx_tst_scb mbx_tst_scb;   // Test -> Scoreboard

    // Packages definition  
    report orden; 
    pkg_trans #(.pckg_sz(pckg_sz))  transaccion_entrante;
    pkg_trans #(.pckg_sz(pckg_sz))  scoreboard[$]; // Estructura dinámica que maneja el scoreboard  
    pkg_trans #(.pckg_sz(pckg_sz))  auxiliar_array[$]; // Estructura auxiliar usada para explorar el scoreboard;  
    
    pkg_trans #(.pckg_sz(pckg_sz))  auxiliar_trans;
    pkg_trans #(.pckg_sz(pckg_sz))  transaction_scb_chk;  
    pkg_chk_scb #(.pckg_sz(pckg_sz)) chk_scb_transaction;

    // Packages for CSV
    pkg_trans #(.pckg_sz(pckg_sz))  csv[$];
    pkg_trans #(.pckg_sz(pckg_sz))  csv_array[$];
    pkg_trans #(.pckg_sz(pckg_sz))  csv_aux;

    function void print_agt();
        $write("[%g] El scoreboard recibe del agente esta transaccion:", $time);
        transaccion_entrante.print();
    endfunction

    task run;
        $display("[%g] El scoreboard se inicializa", $time);
        forever begin
            #20
            // Reads instruction from agent and pushes it into the scoreboard
            // queue
            while(mbx_agt_scb.num > 0) begin
                mbx_agt_scb.get(transaccion_entrante);
              
              	// Creates the object used for generating the path, and assign the elements it needs to make it
                mesh = new(transaccion_entrante.dato_pkg.mode, transaccion_entrante.path);
              	mesh.src = transaccion_entrante.dato_pkg.src;
              	mesh.destiny = {transaccion_entrante.dato_pkg.target.row, transaccion_entrante.dato_pkg.target.col};
	            mesh.run(); 
				transaccion_entrante.path = mesh.path;
              
                this.print_agt();
             
              	// Stores values at a queue for printing the report later
                scoreboard.push_back(transaccion_entrante);

                // The transaction received from the agent - scoreboard is sent to the golden reference of the checker
                transaction_scb_chk = new();
                transaction_scb_chk = transaccion_entrante;
                mbx_scb_chk.put(transaccion_entrante);
                $display("El scoreboard envia transaccion al checker para usar en el GR");
				transaccion_entrante.print();
            end

            // Checks if any completed transaction from checker
            mbx_chk_scb.get(chk_scb_transaction);
            chk_scb_transaction.print("El scoreboard recibe del checker: ");

            if(chk_scb_transaction.completado) begin
            	retardo_total = retardo_total + chk_scb_transaction.latencia;
                tot_bw        = tot_bw + chk_scb_transaction.bw;

            	// Conditions for storing the maximum or minimum bandwidth
            	if (chk_scb_transaction.bw < min_bw) begin
              		min_bw = chk_scb_transaction.bw;
                end
                if (chk_scb_transaction.bw > max_bw) begin
                    max_bw = chk_scb_transaction.bw;
                end
                transacciones_completadas++;
            end

            chk_scb_transaction.cantidad_transacciones = transacciones_completadas; 
            // Pushes data from chk_scb for generating the csv file
            csv.push_back(transaccion_entrante);

            if(mbx_tst_scb.num() > 0) begin
                -> reporte_gen;
            end

        end

    endtask
                		
    // Prints the report or the average delay
    task run_rep;
        @reporte_gen;
        if(mbx_tst_scb.num() > 0) begin
        #1000
        mbx_tst_scb.get(orden);
        case(orden)
            retraso: begin  //average delay
                $display("scoreboard: recibida orden retraso_promedio");
                retardo_promedio = retardo_total/transacciones_completadas;
                avg_bw           = tot_bw/transacciones_completadas;
                $display("[%g] scoreboard: el retardo promedio es: %0.3f s", $time, retardo_promedio);
                $display("[%g] scoreboard: el ancho de banda promedio es: %0.3f Gbps", $time, avg_bw);
                $display("[%g] scoreboard: el ancho de banda minimo es: %0.3f Gbps", $time, min_bw);
                $display("[%g] scoreboard: el ancho de banda maximo es: %0.3f Gbps", $time, max_bw);
            end
            reporte: begin  //report
                $display("scoreboard: recibida orden reporte");
                tamano_scb = scoreboard.size();
                for(int i = 0; i < tamano_scb; i++) begin
                    auxiliar_trans = scoreboard.pop_front;
                    $display("SCB_Report:");
		    		auxiliar_trans.print();
                    auxiliar_array.push_back(auxiliar_trans);
                end
                scoreboard = auxiliar_array;

                // For generating the csv file
                $display("scoreboard: escribiendo en archivo csv");
                csv_size = csv.size();
              
                // Opens the file in write mode
                file = $fopen("Reportes/report.csv", "w");
                //file = $fopen("report.csv", "w");
                // Writes the header of the file
                $fwrite(file, "Dato,Fila,Columna,Fuente,Tiempo envio(ns)\n");
                for(int i = 0; i < csv_size; i++) begin
                    csv_aux = csv.pop_front();
                    //csv_aux.print_rpt();
                    //Writes data into the file
                    $fwrite(file, "%h,%0d,%0d,%0d,%3d\n",
                            csv_aux.dato_pkg.payload, csv_aux.dato_pkg.target.row,
                            csv_aux.dato_pkg.target.col,
                            csv_aux.dato_pkg.src,
                            csv_aux.t_envio);
                    csv_array.push_back(csv_aux);
                end
                $fclose(file);
                //csv = csv_array;

                //bw_file = $fopen("Reportes/bw_report.csv", "r");
		        //if (bw_file == 0) begin
		        //    bw_file = $fopen("Reportes/bw_report.csv", "w");
                //    $fwrite(bw_file, "Cantidad drvrs ,Ancho de banda máximo (Gbps), Ancho de banda mínimo (Gbps)\n");
		        //    $fclose(bw_file);
		        //end
		        //bw_file = $fopen("Reportes/bw_report.csv", "a");
                //$fwrite(bw_file, "%3d,%f,%f\n",
                //        drvrs,max_bw, min_bw);
                //$fclose(bw_file);
            end
        endcase
        end
    endtask
endclass
