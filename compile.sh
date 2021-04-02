#!/bin/bash

gcc -DN=$N -c -Wall -Wextra -O2 -std=c11 -o unit_test.o unit_test.c
nasm -DN=$N -f elf64 -w+all -w+error -o notec.o notec.asm
gcc notec.o unit_test.o -lpthread -o example
