// This class models the monitor, it will read the DUT output and pass it to
// the checker
class monitor #(parameter pckg_sz = 25);
    int terminal;

    // Required mailboxes handlers
    trans_2_mbx #(.pckg_sz(pckg_sz)) mbx_mnt_chk;

    // Packages handlers
    // this pkg containt the info that will be send to the checker
    pkg_trans_2 #(.pckg_sz(pckg_sz)) transaction;

    // Virtual interface, this is used for connecting with DUT
    virtual if_dut #(.pckg_sz(pckg_sz)) vif;

    virtual task run();
        $display("[%g] El monitor (%2d) se inicia", $time, this.terminal);
        @(posedge vif.clk);
        forever begin
            // Waits for the driver to set the pop signal to 1, and when it
            // does, monitor will read the data from DUT and store it at the
            // transaction that goes to checker
            transaction = new();
            $display("[%g] El monitor (%2d) espera algo del DUT", $time, this.terminal);

            @(posedge vif.pndng[this.terminal]);
            vif.pop[this.terminal] = 1;
            @(posedge vif.clk);
            vif.pop[this.terminal] = 0;
          
			transaction.t_recibo = $time;
            $display("[%g] El monitor (%2d) recibe algo del DUT, ahora esto se envia al checker", $time, this.terminal);
            transaction.dato_pkg = vif.data_out[this.terminal];
            transaction.print();

            // Once it has the data now monitor has to send it to checker
            mbx_mnt_chk.put(transaction);
        end
    endtask
endclass
