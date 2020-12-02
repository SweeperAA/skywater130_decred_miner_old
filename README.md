# skywater130_decred_miner

### Overlay
Download the repo and overlay contents into caravel directory.

### Synthesizing
This step currently does not pass entire openlane flow process. For faster debugging, change verilog/rtl/decred_top/rtl/src/decred.v ".NUM_OF_MACROS" to 1.
```
cd caravel/openlane
make decred_top
```
