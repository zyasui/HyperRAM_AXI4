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
with a data/instruction cache memory.



<AXI4 Interfaces>
Sm_AXI is an AXI4 slave port with INC/WRAP burst support to access the
HyperRAM device memory space.

Sr_AXI is an AXI4-Lite slave port to control input delay taps for DQ[7:0]
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
If your system has a cache memory, you will need to change the "Wrap Burst
Length" parameter of this IP to match the same byte length as the cache line
length.



<Clock input ports>
This IP has four clock input ports.
  REFCLK200M:
    This clock input port shall be fed a 200MHz fixed frequency clock for
    the internal IDELAYCTRL module.

  AXI_ACLK:
    This clock is used as the AXI4 bus clock.

  IOCLK_0:
    This clock is used for the HyperRAM bus clock (CK and CK_N outputs).
    The frequency of CK and CK_N outputs are same to IOCLK_0/IOCLK_90 inputs.
    When IOCLK_0 and AXI_ACLK are exact same signal (same frequency, same
    phase), the "SAME_CLOCK_MODE" IP core option can be set to 1. In this
    case, the internal clock synchronization logic is omitted to minimize
    internal latency.

  IOCLK_90:
    90 degree lag version of IOCLK_0.



<TODO>
 * This IP doesn't support additional latency requests where the device
   temporarily stops RSDS transitions. This limitation should be no problem
   for the S27KL0641 device, but it may cause a problem in other devices.

 * This IP supports the INCR and WRAP of AXI4 burst types, but the FIXED
   type of burst is not supported. As per the AXI4 specification, if a
   transaction with unsupported burst type is issued by a master, a SLVERR
   response on BRESP (for a write transaction) or ARESP (for a read
   transaction) should be returned to the master, but this IP core doesn't
   return any response.



<Calibration>
This IP requires a delay tap calibration process for DQ[7:0] and RWDS lines
at the system start-up. A calibration code example is shown below.

------
#include <stdint.h>
#include <stdbool.h>
#include <xil_cache.h>

static uint32_t lfsr32(void);
static uint32_t lfsr_var = 0x12345678;

/*
 * Argument:
 *   reg_base: HyperRAM_AXI4 IP AXI4-Lite register space base address.
 *   mem_base: HyperRAM_AXI4 IP AXI4 memory space base address. This function uses the first 8192 bytes of memory space for testing.
 *
 * Return:
 *   true:  Calibration failed.
 *   false: Calibration succeeded.
 */
bool HyperRAM_DelayCalibration(uint32_t reg_base, uint32_t mem_base)
{
	uint32_t pass_fail_map;	// 0:pass 1:fail
	uint32_t rand_val;
	int tap, i, start;

	Xil_DCacheDisable();

	// Reset delay tap value
	*(volatile uint32_t *)reg_base = 0x2;

	// Create the Pass/Fail map
	pass_fail_map = 0;
	for(tap=0; tap!=32; tap++) {
		for(i=0; i!=1024; i++) {
			rand_val = lfsr32();
			*(volatile uint32_t *)(mem_base + i * 4)        = rand_val;
			*(volatile uint32_t *)(mem_base + i * 4 + 4096) = rand_val;
		}
		for(i=0; i!=1024; i++) {
			if(*(volatile uint32_t *)(mem_base + i * 4) != *(volatile uint32_t *)(mem_base + i * 4 + 4096))
				break;
		}
		if(i != 1024)
			pass_fail_map |= 1ul << tap;	// mark as "fail"

		// Increment delay tap value
		*(volatile uint32_t *)reg_base = 0x1;
	}

	// Check the Pass/Fail map
	start = 0;
	for(tap=0; tap!=32; tap++) {
		if(pass_fail_map & (1ul << tap)) {
			// Failed tap position found
			if((tap - start) >= 8)
				// There is a wide "safety island"
				break;
			else
				start = tap;	// check again
		}
	}
	if((tap == 32) && ((tap - start) < 8))
		// We couldn't find an optimal tap position.
		return true;

	// Reset delay tap value
	*(volatile uint32_t *)reg_base = 0x2;
	for(i=0; i!=(tap + start)>>1; i++)
		// Increment the delay tap value to the middle of "safety island"
		*(volatile uint32_t *)reg_base = 0x1;

	// Final check
	for(i=0; i!=1024; i++) {
		rand_val = lfsr32();
		*(volatile uint32_t *)(mem_base + i * 4)        = rand_val;
		*(volatile uint32_t *)(mem_base + i * 4 + 4096) = rand_val;
	}
	for(i=0; i!=1024; i++) {
		if(*(volatile uint32_t *)(mem_base + i * 4) != *(volatile uint32_t *)(mem_base + i * 4 + 4096))
			break;
	}
	if(i != 1024)
		return true;	// data error

	Xil_DCacheEnable();

	return false;
}

static uint32_t lfsr32(void)
{
	lfsr_var = (lfsr_var & 1) ? (lfsr_var >> 1) ^ 0xa3000000 : (lfsr_var >> 1);

	return lfsr_var;
}
------
