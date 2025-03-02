#ifndef PQCLEAN_MCELIECE348864_CLEAN_CONTROLBITS_H
#define PQCLEAN_MCELIECE348864_CLEAN_CONTROLBITS_H
/*
  This file is for functions required for generating the control bits of the Benes network w.r.t. a random permutation
  see the Lev-Pippenger-Valiant paper https://www.computer.org/csdl/trans/tc/1981/02/06312171.pdf
*/


#include <stdint.h>
#include "memory_pool.h"
#ifndef PC
#include "printf.h"
#else
#include <stdio.h>
#endif

void PQCLEAN_MCELIECE348864_CLEAN_sort_63b(int n, uint64_t *x);
void PQCLEAN_MCELIECE348864_CLEAN_controlbits(unsigned char *out, const uint32_t *pi);

#endif

