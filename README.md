# sandino

Sandino is the RTL implementation (in VHDL) of a fully by-passed 5-stage processor adapted from the beta processor of [MIT 6.004 class](https://computationstructures.org/)

In addition Sandino contains the following:
* An instruction cache (direct-mapped)
* A data cache (3-way associative) 
* A TLB (fully associative) 
* A tournament branch predictor(composed of a local and global predictor)
