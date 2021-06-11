/**
 * @brief Simple djb2 hash function implementation
 *
 * gcc hash.c -o hash
 * gcc -S hash.c -o hash.s 
*/

#include <stdio.h>
#include <stdint.h>

#define __DJB2_MAGIC_INIT (5381UL)

typedef unsigned char byte_t;

uint64_t djb2(byte_t* in, size_t len)
{
    uint64_t hash;
    size_t i;

    hash = __DJB2_MAGIC_INIT;

    for (i = 0; i < len; i++) {
        hash += ((hash << 5) + hash) + in[i]; // hash * 33 + in[i]
    }
    
    return hash;
}

void main(int argc, char** argv)
{
    uint64_t hash;
    byte_t secret[] = "aaaaaaaaa";

    hash = djb2(secret, sizeof(secret) / sizeof(*secret));

    printf("%lx\n", hash);
}