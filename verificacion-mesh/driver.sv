// This class is for doing the driver work, should put the data into the DUT,
// so it has to follow the way of communicating with it
class driver #(parameter pckg_sz   = 25,
               parameter fifo_dpth = 8);

    int terminal;
    int espera;

    // Instances of the mailbox required
    // mbx trans, this gives all transaction info
    trans_mbx #(.pckg_sz(pckg_sz)) mbx_agt_drv;

    // Packages instances
    // this pkg contains all the transaction info
    pkg_trans #(.pckg_sz(pckg_sz)) transaction;

    // Virtual interface, this is used for connecting with DUT
    virtual if_dut #(.pckg_sz(pckg_sz)) vif;

    // Declares the fifo required for input to the DUT
    int fifo_in[$:fifo_dpth];
   
    task run();
        $display("[%g] El driver (%2d) se inicia", $time, this.terminal);
        @(posedge vif.clk);
        // Reads from agent, and generates de required stimulus for DUT to
        // work properly: put data and set pending signal
        forever begin
            transaction = new();

            $display("[%g] El driver (%2d) espera por un item del agente", $time, this.terminal);
            mbx_agt_drv.get(transaction);
            $display("[%g] El driver (%2d) recibe instruccion del agente", $time, this.terminal);
            /* `ifdef DEBUG */
                transaction.print();
            /* `endif */

            vif.pndng_i_in[this.terminal] = 0;

            // Waits for the delay to pass
            espera = 0;
            $display("[%g] El driver (%2d) espera retardo de %2d clk", $time, this.terminal, transaction.retardo);
            while(espera < transaction.retardo) begin
                @(posedge vif.clk);
                espera = espera + 1;
            end
            $display("[%g] El driver (%2d) ha terminado la espera de %2d clk", $time, this.terminal, transaction.retardo);

            // Just in case there is a reset instruction then it will do it,
            // else it should work as normal
            if(transaction.tipo == reset_type) begin
                vif.reset = 1;
                @(posedge vif.clk);
                @(posedge vif.clk);
                vif.reset = 0;
            end
            
            // If in pkg received push == 1, then load into the queue and put
            // pndng signal to 1
            else begin
                if(transaction.push[this.terminal]) begin
                    transaction.t_envio = $time;
                    fifo_in.push_back(transaction.dato_pkg);

                    vif.pndng_i_in[this.terminal]    = 1;
                    vif.data_out_i_in[this.terminal] = fifo_in.pop_front();
                end
    
                // Waits por pop signal to occur
                @(negedge vif.popin[this.terminal]);
    
                // If there are no more elements at queue then set pndng to 0
                if(fifo_in.size() == 0) begin
                    vif.pndng_i_in[this.terminal] = 0;
                end
            end
        end
    endtask

endclass
