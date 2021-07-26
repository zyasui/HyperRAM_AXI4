Copyright (C) 2021 YASUI Tsukasa. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice,
     this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in the
     documentation and/or other materials provided with the distribution.

  3. All advertising materials mentioning features or use of this software
     must display the following acknowledgement: This product includes
     software developed by YASUI Tsukasa. Neither the name of YASUI Tsukasa
     nor the names of its contributors may be used to endorse or promote
     products derived from this software without specific prior written
     permission.

THIS SOFTWARE IS PROVIDED BY YASUI Tsukasa AS IS AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL YASUI Tsukasa BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 



<Abstract>
This IP is an AXI4-HyperRAM(TM) controller for Xilinx 7-Series FPGAs.
This IP has been tested with Cypress/Infineon S27KL0641 and Microblaze
w/data-cache.



<AXI4 Interfaces>
Sm_AXI is an AXI4 slave port with INC/WRAP burst support to access the
HyperRAM device..

Sr_AXI is an AXI4-Lite slave port to control input delay taps for RQS[7:0]
and RWDS signals.

Sr_AXI space register definition:
  Addr=0x00000000 (Write only register, 8/16/32-bit accesible)
    Bit 1: Write 1 to reset each delay tap to zero (minimum) delay.
           This bit is automatically cleared, so the software doesn't need to
           write zero to this bit.

    Bit 0: Write 1 to increment each delay tap value. If the delay tap value
           before incrementing is 31, the next value is undefined.
           This bit is automatically cleared, so the software doesn't need to
           write zero to this bit.

    Writing 1 for both bits causes undefined results.



<Using this IP with cache memory>
If your system has a cache memory, you will need to change the "Wrap Burst Len"
parameter of this IP to match the same byte length as the cache line length.



<TODO>
 * This IP doesn't support additional latency requests where the device
   temporarily stops RSDS transitions. This limitation should be no problem
   for the S27KL0641 device, but that may cause a problem in other devices.

 * This IP supports INCR and WRAP AXI4 burst access types, but FIXED burst
   type is not supported.
