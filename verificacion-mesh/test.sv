// This class makes it possible to generate stimulus for the DUT, basically it
// will tell the generator what test should do
class test #(parameter pckg_sz = 25, parameter fifo_dpth = 8);

    // Parameters for transactions
    parameter transaccion_aleatoria  = 0;
    parameter cantidad_transacciones = 2;

    // Mailboxes declaration
    trans_mbx #(.pckg_sz(pckg_sz)) mbx_gen_agt;     // Generator -> Agent
    trans_mbx #(.pckg_sz(pckg_sz)) mbx_agt_drv[16]; // Agent -> Driver
    trans_mbx #(.pckg_sz(pckg_sz)) mbx_agt_scb;     // Agent -> Scoreboard
    trans_2_mbx #(.pckg_sz(pckg_sz)) mbx_mnt_chk;   // Monitor -> Checker
    trans_mbx #(.pckg_sz(pckg_sz)) mbx_tst_gen;     // Test -> Generator
    trans_mbx #(.pckg_sz(pckg_sz)) mbx_scb_chk;     // Scoreboard -> Checker
    trans_mbx #(.pckg_sz(pckg_sz)) mbx_chk_scb;     // Checker -> Scoreboard
    trans_mbx_tst_scb  mbx_tst_scb;     // Test -> Scoreboard

    // Packages for sending information
    pkg_trans #(.pckg_sz(pckg_sz)) transaction;
    report instr_scb;  

    // Environment instance
    ambiente #(.pckg_sz(pckg_sz), .fifo_dpth(fifo_dpth)) amb;

    // Virtual interface, this is used for connecting with DUT
    virtual if_dut #(.pckg_sz(pckg_sz)) vif;

    // Connects all mailboxes and interfaces
    function new();

        // Starts each mbx
        mbx_gen_agt = new();
        mbx_agt_scb = new();
        mbx_mnt_chk = new();
        mbx_tst_gen = new();
        mbx_scb_chk = new();
        mbx_chk_scb = new();
        mbx_tst_scb = new();
        // ENVIRONMENT
        amb     = new();
        amb.vif = vif;

        // This for generates all the mbx_agt_drv
        for(int i = 0; i < 16; i++) begin
            mbx_agt_drv[i] = new();
            amb.agt.mbx_agt_drv[i] = mbx_agt_drv[i];
        end

        // AGENT - DRIVER
        for(int i = 0; i < 16; i++) begin
            amb.mbx_agt_drv[i]           = mbx_agt_drv[i];
            amb.drv_array[i].mbx_agt_drv = mbx_agt_drv[i];
        end

        // TEST - GENERATOR
        amb.mbx_tst_gen     = mbx_tst_gen;
        amb.gen.mbx_tst_gen = mbx_tst_gen;

        // GENERATOR - AFENT
        amb.mbx_gen_agt     = mbx_gen_agt;
        amb.gen.mbx_gen_agt = mbx_gen_agt;
        amb.agt.mbx_gen_agt = mbx_gen_agt;

        // GENERATOR - SCOREBOARD
        amb.agt.mbx_gen_agt = mbx_gen_agt;

        // AGENT - SCOREBOARD
        amb.agt.mbx_agt_scb = mbx_agt_scb;
		amb.scb.mbx_agt_scb = mbx_agt_scb;

        // MONITOR - CHECKER
        amb.mbx_mnt_chk = mbx_mnt_chk;
      	amb.chk.mbx_mnt_chk = mbx_mnt_chk;
        for(int i = 0; i < 16; i++) begin
            automatic int k = i;
            amb.mnt_array[k].mbx_mnt_chk = mbx_mnt_chk;
        end

         // TEST - SCOREBOARD
        amb.mbx_tst_scb            = mbx_tst_scb;
        amb.scb.mbx_tst_scb   = mbx_tst_scb;

        // SCOREBOARD - CHECKER
        amb.mbx_scb_chk            = mbx_scb_chk;      
        amb.scb.mbx_scb_chk   = mbx_scb_chk;
        amb.chk.mbx_scb_chk        = mbx_scb_chk;    
        
        // checker scoreboard
        amb.mbx_chk_scb            = mbx_chk_scb;
        amb.chk.mbx_chk_scb        = mbx_chk_scb;
        amb.scb.mbx_chk_scb   = mbx_chk_scb;

        // Randomization transactions generator
        amb.gen.transaccion_aleatoria  = transaccion_aleatoria;
        amb.gen.cantidad_transacciones = cantidad_transacciones;

    endfunction

    // Sets the test and starts the environment run task
    virtual task run();
        $display("[%g] El test se inicia", $time);
        fork
            amb.run();
        join_none

        transaction = new();
        transaction.tipo = envio_rdm;
        amb.gen.modo_aux = 1'b0;
        amb.gen.col_aux = 4'b0101;
        amb.gen.row_aux = 4'b0011;
        amb.gen.src_aux = 4'b0100;
        amb.gen.payload_aux = 4'b1010;
        mbx_tst_gen.put(transaction);

        instr_scb = reporte;
        // instr_scb = retrasos;
        mbx_tst_scb.put(instr_scb);
 
    endtask
endclass
