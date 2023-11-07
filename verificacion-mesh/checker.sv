// Class for modeling the checker
class checker #(parameter pckg_sz   = 25,
               	parameter fifo_dpth = 8);

    // Associative array for storing things from scoreboard
    int historial[logic [pckg_sz-1:0]];
    
    // Creates packages
  	pkg_trans #(.pckg_sz(pckg_sz))  scb_chk_transaction;
  	pkg_trans_2 #(.pckg_sz(pckg_sz)) mnt_chk_transaction;
  	pkg_chk_scb #(.pckg_sz(pckg_sz)) chk_scb_transaction;
  
    // Mailboxes
  	trans_mbx #(.pckg_sz(pckg_sz)) mbx_scb_chk;   // Scoreboard -> Checker
    trans_mbx_chk_scb #(.pckg_sz(pckg_sz)) mbx_chk_scb;   // Checker -> Scoreboard
  	trans_2_mbx #(.pckg_sz(pckg_sz)) mbx_mnt_chk; // Monitor -> Checker

    // Print function
    function print_mnt();
        $write("[%g] El checker recibe del monitor [%2d] esta instruccion: ", $time, mnt_chk_transaction.dato_pkg.src );
        mnt_chk_transaction.print();
    endfunction

    // Task for executing the module behavior
    task run();
        $display("[%g] El checker se inicializa", $time);
        #10;
        forever begin

            // Initialize package scb-chk
            scb_chk_transaction = new();

            // Receives pkg from monitor and passes some data to scoreboard
            if(mbx_mnt_chk.num() > 0) begin
                mbx_mnt_chk.get(mnt_chk_transaction);
                this.print_mnt();

                $display("[%g] Esperando una instruccion del scoreboard para comparar con lo del monitor", $time);
                while(mbx_scb_chk.num() > 0) begin
                    mbx_scb_chk.get(scb_chk_transaction);

                    // Receives pkg from scoreboard
                  	$display("El checker recibe del scoreboard la siguiente instruccion y la almacena en una tabla: ");
                  	scb_chk_transaction.print();

                    // Stores what was received from scoreboard into a hash table
                    historial[{scb_chk_transaction.dato_pkg.target.row, scb_chk_transaction.dato_pkg.target.col, scb_chk_transaction.dato_pkg.payload}] = scb_chk_transaction.t_envio;
                end
              
              	//Imprime la tabla de Hash
             	//foreach (historial[key]) begin
                  //$display("Clave: %h, Valor: %3d", key, historial[key]);
				//end  
              
              // Golden reference
              if(historial.exists({mnt_chk_transaction.dato_pkg.target.row, mnt_chk_transaction.dato_pkg.target.col, mnt_chk_transaction.dato_pkg.payload})) begin
                $display("[%g] Transaccion correcta", $time);
                $display("[%g] El dato [%h] ha sido almacenado en el scoreboard", $time, mnt_chk_transaction.dato_pkg.payload);
                
                // Gives to the scoreboard the delay and tells if an
                // instruction was completed
                chk_scb_transaction               = new();
                chk_scb_transaction.completado    = 1;
                chk_scb_transaction.t_envio       = historial[{mnt_chk_transaction.dato_pkg.target.row, mnt_chk_transaction.dato_pkg.target.col, mnt_chk_transaction.dato_pkg.payload}];
                chk_scb_transaction.t_recibo      = mnt_chk_transaction.t_recibo;
              
              	// Calculates latency and bandwidth
              	chk_scb_transaction.calc_latencia;
                chk_scb_transaction.calc_bw(pckg_sz);
              
              	// Gives some more data to the pkg
                chk_scb_transaction.data          = mnt_chk_transaction.dato_pkg.payload;
                chk_scb_transaction.row_id        = mnt_chk_transaction.dato_pkg.target.row;
                chk_scb_transaction.col_id        = mnt_chk_transaction.dato_pkg.target.col;
                chk_scb_transaction.src     	  = mnt_chk_transaction.dato_pkg.src;
              
                // Sends the pkg to the scoreboard
                mbx_chk_scb.put(chk_scb_transaction);
              end
              else begin
                $display("[%g] Transaccion incorrecta", $time);
                $display("[%g] El dato [%h] no ha sido almacenado en el scoreboard", $time, mnt_chk_transaction.dato_pkg.payload);
              end
            end


           
            #10;
        end
    endtask
endclass
