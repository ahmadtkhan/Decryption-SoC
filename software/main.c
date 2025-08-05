/*
 * main.c
 *
 *  Created on: 2014-11-15
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>
#include <sys/mman.h>
#include <stdbool.h>
#include <pthread.h>
#include "hwlib.h"
#include "socal/socal.h"
#include "socal/hps.h"
#include "socal/alt_gpio.h"
#include "hps_0.h"
#include "seg7.h"

#define LW_SIZE             0x00200000
#define LWHPS2FPGA_BASE      0xff200000

#define MD5_MSG_WORDS       16   
#define MD5_DIGEST_WORDS    4    

#define SERIAL_MODE         0x00000001
#define PARALLEL_MODE       0xFFFFFFFF

volatile uint32_t *md5_control = NULL;
volatile uint32_t *md5_data = NULL;
volatile uint32_t *h2p_lw_hex_addr = NULL; 

uint32_t test_message[MD5_MSG_WORDS] = {
    0x12345678, 0x9ABCDEF0, 0x13579BDF, 0x2468ACE0,
    0xDEADBEEF, 0xFEEDFACE, 0x0BADF00D, 0xABCDEF01,
    0x11223344, 0x55667788, 0x99AABBCC, 0xDDEEFF00,
    0x0F1E2D3C, 0x4B5A6978, 0x88776655, 0x44332211
};

void reset_system(){
    // Assert reset by writing to md5_control register at offset 1
    alt_write_word(md5_control + 1, 0x1);
    while (!(alt_read_word(md5_control + 1) & 0x1)); // wait for the reset bit to be set

    printf("Reset done. Deasserting signal\n");
    // Wait until the reset signal is deasserted
    while (alt_read_word(md5_control + 1) & 0x1);
}

void md5_write_message() {
    int i;
    for(i = 0; i < MD5_MSG_WORDS; i++){
        alt_write_word(md5_data + 0, test_message[i]);
        alt_write_word(md5_data + 1, i);
        usleep(1000); 
    }
}

void md5_read_digest(uint32_t digest[MD5_DIGEST_WORDS]) {
    int i;
    for(i = 0; i < MD5_DIGEST_WORDS; i++){
        alt_write_word(md5_data + 2, i);
        usleep(1000); 
        digest[i] = alt_read_word(md5_data + 0);
    }
}

void md5_run(uint32_t mode, uint32_t digest[MD5_DIGEST_WORDS], double *elapsed_ms) {
    struct timespec t_start, t_end;
    
    alt_write_word(md5_control + 1, mode);
    usleep(1000);
    alt_write_word(md5_control + 0, mode);
    
    clock_gettime(CLOCK_MONOTONIC, &t_start);
    
    while (alt_read_word(md5_control + 2) == 0);
    
    clock_gettime(CLOCK_MONOTONIC, &t_end);
    
    *elapsed_ms = (t_end.tv_sec - t_start.tv_sec) * 1000.0 +
                  (t_end.tv_nsec - t_start.tv_nsec) / 1000000.0;
    
    md5_read_digest(digest);
}

void display_digest_on_seg7(uint32_t word) {
    SEG7_Hex(word, 0);
}

int main(int argc, char **argv) {
    int fd;
    void *virtual_base;
    
    // Open /dev/mem to access the FPGA address space
    if ((fd = open("/dev/mem", (O_RDWR | O_SYNC))) == -1) {
        printf("ERROR: could not open \"/dev/mem\"...\n");
        return 1;
    }
    
    // Map 2MB of the lightweight bridge memory
    virtual_base = mmap(NULL, LW_SIZE, (PROT_READ | PROT_WRITE), MAP_SHARED, fd, LWHPS2FPGA_BASE);
    if (virtual_base == MAP_FAILED) {
        printf("ERROR: mmap() failed...\n");
        close(fd);
        return 1;
    }
    
    // Initialize pointers to our MD5 IP components and the 7-seg interface
    md5_data = virtual_base + ((uint32_t) MD5_DATA_0_BASE);
    md5_control = virtual_base + ((uint32_t) MD5_CONTROL_0_BASE);
    h2p_lw_hex_addr = virtual_base + ((uint32_t) SEG7_IF_0_BASE);
    
    SEG7_All_Number(); // Display test numbers on 7-seg.
    sleep(1);
    SEG7_Clear();
    
    uint32_t digest[MD5_DIGEST_WORDS];
    double t_serial, t_parallel;
    int iteration = 1;

	reset_system();
    
    while (1) {
        printf("\nIteration %d\n", iteration++);
        
        // Reset the MD5 unit at the start of each iteration
        //reset_system();
        
        // SERIAL MODE: only one MD5 core active (bit 0 set)
        printf("Running MD5 in SERIAL mode...\n");
        md5_write_message();
        md5_run(SERIAL_MODE, digest, &t_serial);
        printf("Serial MD5 digest: ");
        for (int i = 0; i < MD5_DIGEST_WORDS; i++) {
            printf("%08X ", digest[i]);
        }
        printf("\nTime (serial): %.3f ms\n", t_serial);
        display_digest_on_seg7(digest[0]);
        sleep(1);
        
        // Reset again between runs
        //reset_system();
        
        // PARALLEL MODE: all MD5 cores active (all bits set)
        printf("Running MD5 in PARALLEL mode...\n");
        md5_write_message();
        md5_run(PARALLEL_MODE, digest, &t_parallel);
        printf("Parallel MD5 digest: ");
        for (int i = 0; i < MD5_DIGEST_WORDS; i++) {
            printf("%08X ", digest[i]);
        }
        printf("\nTime (parallel): %.3f ms\n", t_parallel);
        display_digest_on_seg7(digest[0]);
        
        sleep(2);
    }
    
    munmap((void *)virtual_base, LW_SIZE);
    close(fd);
    return 0;
}

