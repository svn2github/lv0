# $Id: $

# Copyright (c) 2012 Joerg Zinke <umaxx@lv0.org>
#
# Permission to use, copy, modify, and distribute this software for any purpose
# with or without fee is hereby granted, provided that the above copyright
# notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

# prepare x86_64 kernel environment
# bootcd and boothd load this code at physical address 0x8000 (32KB) 
.global _start
.global pixel 

.set BIOS_SERIAL, 0x14          # bios serial port interrupt
.set BIOS_SYSTEM, 0x15          # bios miscellaneous system port interrupt
.set BIOS_VIDEO, 0x10           # bios video services interrupt
.set GDT_CODE32, 0x08           # offset gdt entry 32 bit code segment
.set GDT_CODE64, 0x10           # offset gdt entry 64 bit code segment
.set GDT_DATA, 0x18             # offset gdt entry data segment
.set MEMORY, 0x3000             # memory bitmap build from e820
.set PML4T, 0x1000              # page map level 4 table
.set PDPT, 0x2000               # page directory pointer table
.set PDT, 0x10000               # page directory table
.set VESA_MODE, 0x0115          # vesa mode 800x600 and 24bpp
.set VIDEO_PORT, 0x3d4          # video port

# linker entry point of bootsector
.code16
_start:
        cli                     # disable interrupts
        cld                     # clear direction flag for string operations
        xorw    %ax, %ax        # zero ax
        movw    %ax, %ds        # setup the data segment
        movw    %ax, %es        # setup the extra segment
        movw    %ax, %ss        # setup the stack segment
        movw    $_start, %sp    # set stack pointer to 0x8000 growing downwards
        call    serial          # initialize serial port
        call    a20             # enable a20 gate
        call    cpu             # check cpuid for long mode
        call    memory          # read memory map with e820
        call    vesa            # initialize vesa
        # switch to protected mode
        lgdt    gdtr32          # load global descriptor table
        movl    %cr0, %eax      # get cr0
        orl     $1, %eax        # enable protected mode by setting lowest bit
        movl    %eax, %cr0      # switch to protected mode
        ljmp    $GDT_CODE32, $start32  # start protected mode at gdt offset

# initialize serial port
serial:
        enter   $0, $0          # handle base pointer and stack pointer
        pushw   %ax             # preserve ax register on stack
        pushw   %dx             # preserve ax register on stack
        movb    $0, %ah         # serial port initialization
        movb    $0xe3, %al      # 11100011b means 9600 baud 8N1
        movw    $0, %dx         # serial port number 0
        int     $BIOS_SERIAL    # call bios serial port function
        popw    %dx             # restore dx register from stack
        popw    %ax             # restore ax register from stack
        leave                   # restore base pointer and stack pointer
        ret                     # return

# enable a20 gate
a20:
        enter   $0, $0          # handle base pointer and stack pointer
        pushw   %ax             # preserve ax register on stack
        call    wait_keyboard   # wait for keyboard controller
        movb    $0xd1, %al      # set write command
        outb    %al, $0x64      # send command to controller
        call    wait_keyboard   # wait for keyboard controller
        movb    $0xdf, %al      # set enable a20 command
        outb    %al, $0x60      # send enable command to chip
        call    wait_keyboard   # wait for keyboard controller
        popw    %ax             # restore ax register from stack
        leave                   # restore base pointer and stack pointer
        ret                     # return

# wait for 8042 keyboard controller
wait_keyboard:
        enter   $0, $0          # handle base pointer and stack pointer
        pushw   %ax             # preserve ax register on stack
        inb     $0x64, %al      # get status from keyboard controller
        testb   $0x2, %al       # test if controller is busy
        jnz     wait_keyboard   # loop until controller is not busy
        popw    %ax             # restore ax register from stack
        leave                   # restore base pointer and stack pointer
        ret                     # return

# check cpu id for long mode
cpu:
        enter   $0, $0          # handle base pointer and stack pointer
        pushl   %eax            # preserve eax register on stack
        pushl   %ebx            # preserve ebx register on stack
        pushl   %ecx            # preserve ecx register on stack
        pushl   %edx            # preserve edx register on stack
        movl    $0x80000000, %eax # largest extended function number 
        cpuid                   # CPU identification
        cmpl    $0x80000001, %eax # check if 0x80000001 function is available
        jb      cpu_error       # if less no long mode can not be tested
        mov     $0x80000001, %eax # extended function number for features 
        cpuid                   # CPU identification
        btl     $29, %edx       # feature identifier long mode in edx bit 29 
        jnc     cpu_error       # if not set there is no long mode
        popl    %edx            # restore edx register from stack
        popl    %ecx            # restore ecx register from stack
        popl    %ebx            # restore ebx register from stack
        popl    %eax            # restore eax register from stack
        leave                   # restore base pointer and stack pointer
        ret                     # return
cpu_error:
        movl    $error_cpu, %esi # set error cpu message
        call    print           # print message
        hlt                     # halt

# read memory map via bios function e820
memory:
        enter   $0, $0          # handle base pointer and stack pointer
        pushl   %eax            # preserve eax register on stack
        pushl   %ebx            # preserve ebx register on stack
        pushl   %ecx            # preserve ecx register on stack
        pushl   %edx            # preserve edx register on stack
        pushw   %di             # preserve di register on stack
        pushw   %es             # preserve es register on stack
        # get e820 memory map from bios
        movw    $e820, %di      # set memory destination buffer 
        xorl    %ebx, %ebx      # zero ebx
memory_e820:
        movl    $0x0820, %eax   # get system memory map function number
        movl    $24, %ecx       # request 24 bytes
        movl    $0x534d4150, %edx # set string SMAP
        int     $BIOS_SYSTEM    # call bios system function
        # todo check for error and set bits in memory map $MEMORY for entries found
        # phlox, ibox and sartoris
        popw    %es             # restore es register from stack
        popw    %di             # restore di register from stack
        popl    %edx            # restore edx register from stack
        popl    %ecx            # restore ecx register from stack
        popl    %ebx            # restore ebx register from stack
        popl    %eax            # restore eax register from stack
        leave                   # restore base pointer and stack pointer
        ret                     # return
memory_error:
        movl    $error_memory, %esi # set error memory message
        call    print           # print message
        hlt                     # halt

# initialize vesa graphics mode
vesa:
        enter   $0, $0          # handle base pointer and stack pointer
        pushw   %ax             # preserve ax register on stack
        pushw   %bx             # preserve bx register on stack
        pushw   %cx             # preserve cx register on stack
        pushw   %di             # preserve di register on stack
        pushw   %es             # preserve es register on stack
        # get vesa mode information from bios
        movw    $vesa_mode, %di # set vesa mode information destination buffer 
        movw    $0x4f01, %ax    # set vesa mode information function number
        movw    $VESA_MODE, %cx # set vesa mode number
# todo  #xorw    $0x4000, %bx    # set request linear frame buffer bit
        int     $BIOS_VIDEO     # call bios video function
        cmpw    $0x004f, %ax    # test if vesa call successful
        jne     vesa_error      # if not succesful no vesa 
        # set vesa mode
        movw    $0x4f02, %ax    # set vesa mode information function number
        movw    $VESA_MODE, %bx # set vesa mode number
# todo  #xorw    $0x4000, %bx    # set request linear frame buffer bit
        int     $BIOS_VIDEO     # call bios video function
        cmpw    $0x004f, %ax    # test if vesa call successful
        jne     vesa_error      # if not succesful no vesa 
        popw    %es             # restore es register from stack
        popw    %di             # restore di register from stack
        popw    %cx             # restore cx register from stack
        popw    %bx             # restore bx register from stack
        popw    %ax             # restore ax register from stack
        leave                   # restore base pointer and stack pointer
        ret                     # return
vesa_error:
        movl    $error_vesa, %esi # set error vesa message
        call    print           # print message
        hlt                     # halt

# print null terminated string to serial and video
print:
        enter   $0, $0          # handle base pointer and stack pointer
        pushw   %ax             # preserve ax register on stack
        pushw   %bx             # preserve bx register on stack
        pushw   %dx             # preserve dx register on stack
print_character:
        lodsb                   # read character
        cmpb    $0, %al         # check if end of string reached
        je      print_done      # nothing more to print
        movb    $0x01, %ah      # write character to serial port
        movw    $0, %dx         # serial port number 0
        int     $BIOS_SERIAL    # call bios serial function
        movb    $0x0e, %ah      # display character on screen
        movw    $0x07, %bx      # page 0 and color white
        int     $BIOS_VIDEO     # call bios video function
        jmp     print_character # loop until end of string is reached
print_done:
        popw    %dx             # restore dx register from stack
        popw    %bx             # restore bx register from stack
        popw    %ax             # restore ax register from stack
        leave                   # restore base pointer and stack pointer
        ret                     # return

# protected mode
.code32
start32:
        movl    $GDT_DATA, %eax # set gdt data segment offset
        movl    %eax, %ds       # setup the data segment
        movl    %eax, %es       # setup the extra segment
        movl    %eax, %ss       # setup the stack segment
        xorl    %eax, %eax      # zero eax
        movl    %eax, %fs       # setup the additional extra segment
        movl    %eax, %gs       # setup the additional extra segment
        movl    $_start, %esp   # set stack pointer to 0x8000
                                # stack grows downwards from 0x8000
        call    pages           # setup identity mapped paging
        # point cr3 to PML4T
        movl    $PML4T, %eax    # set address to PML4T
        movl    %eax, %cr3      # point cr3 to PML4T
        # enable extended properties
        movl    %cr4, %eax      # get cr4
        orl     $0xb0, %eax     # set PGE and PAE and PSE bits 
        movl    %eax, %cr4      # store extended properties
        # enable long mode and syscall and sysret
        movl    $0xc0000080, %ecx # set extended feature register number
        rdmsr                   # read extended feature register
        orl     $0x0101, %eax   # set syscall and sysret and long mode bits 
        wrmsr                   # write extended feature register
        # enable paging and switch to long mode
        movl    %cr0, %eax      # get cr0
        orl     $0x80000000, %eax # set enable paging bit
        movl    %eax, %cr0      # switch to long mode
        lgdt    gdtr64          # load global descriptor table
        ljmp    $GDT_CODE64, $start64  # start protected mode at gdt offset

# setup PML4T and PDPT and PDT for identity mapped paging with 2MB page size
pages:
        enter   $0, $0          # handle base pointer and stack pointer
        pushl   %eax            # preserve eax register on stack
        pushl   %ecx            # preserve ecx register on stack
        pushl   %edi            # preserve edi register on stack
        pushl   %esi            # preserve esi register on stack
        # zero 2 * 4KB of memory for PML4T and PDPT
        xorl    %eax, %eax      # zero eax
        movl    $PML4T, %edi    # set destination to PML4T 
        movl    $2048, %ecx     # set count 2048 * 4B = 8KB
        rep                     # repeat
        stosl                   # clear the memory
        # PML4T at 0x1000 with 512 entries * 8 Byte = 4KB
        # a single PML4T entry can map up to 512GB with 2MB pages
        # first entry is pointing to PDPT
        movl    $PML4T, %edi    # set destination to PML4T
        movl    $PDPT, %eax     # point first PML4T entry to PDPT 
        orl     $0x03, %eax     # set page entry present and rw bits
        stosl                   # store first entry
        # PDPT at 0x2000 with 512 entries * 8 Byte = 4KB
        # a single PDPT entry can map up to 1GB with 2MB pages
        # first entry is pointing to PDT
        movl    $PDPT, %edi     # set destination to PDPT
        movl    $PDT, %esi      # first entry point to PDT
        orl     $0x03, %esi     # set page entry present and rw bits
        movl    $64, %ecx       # create 64 PDPT entries
pages_pdpte:
        movl    %esi, %eax      # set entry
        stosl                   # store entry
        xorl    %eax, %eax      # zero eax
        stosl                   # store entry
        addl    $0x1000, %esi   # each PDPT entry is 512 entries * 8 bytes = 4KB 
        decl    %ecx            # decrement count
        cmpl    $0, %ecx        # check if done
        jne     pages_pdpte     # loop if not done required
        # zero 256KB of memory for 64 PDT
        xorl    %eax, %eax      # zero eax
        movl    $PDT, %edi      # set destination to PDT table
        movl    $65536, %ecx    # set count 65536 * 4B = 256KB
        rep                     # repeat
        stosl                   # clear the memory
        # PDT at 0x10000 with 64 entries with each 512 entries * 8 Byte = 256KB
        # identity map up to 64 GB with 2 MB pages start with 4GB
        movl    $PDT, %edi      # set destination to PDPT
        xorl    %esi, %esi      # zero esi
        orl     $0x83, %esi     # set page entry present and rw and 2 MB pages
        movl    $2048, %ecx     # create 2048 * 2MB PDTE = 4GB
pages_pdte:
        movl    %esi, %eax      # set entry
        stosl                   # store first entry
        xorl    %eax, %eax      # zero eax
        stosl                   # store entry
        addl    $0x200000, %esi # each PDT page entry is 2MB  
        decl    %ecx            # decrement count
        cmpl    $0, %ecx        # check if done
        jne     pages_pdte      # loop if not done required
        popl    %esi            # restore esi register from stack
        popl    %edi            # restore edi register from stack
        popl    %ecx            # restore ecx register from stack
        popl    %eax            # restore eax register from stack
        leave                   # restore base pointer and stack pointer
        ret                     # return

# long mode
.code64
start64:
        xorq    %rax, %rax      # zero rax
        xorq    %rbx, %rbx      # zero rbx
        xorq    %rcx, %rcx      # zero rcx
        movq    $_start, %rsp   # set stack pointer to 0x8000
                                # stack grows downwards from 0x8000
        lgdt    gdtr64          # reload global descriptor table
        call    main            # call into c
        hlt                     # halt

# draw pixel to video
pixel:
        enter   $0, $0          # handle base pointer and stack pointer
        pushq   %rax            # preserve rax register on stack
        pushq   %rbx            # preserve rbx register on stack
        pushq   %rdx            # preserve rdx register on stack
        pushq   %rdi            # preserve rdi register on stack
        pushq   %rsi            # preserve rsi register on stack
        pushq   %r11            # preserve r11 register on stack
        pushq   %r12            # preserve r12 register on stack
        pushq   %r13            # preserve r13 register on stack
        pushq   %r14            # preserve r14 register on stack
        movq    %rdi, %r11      # move first argument x
        movq    %rsi, %r12      # move second argument y
        movq    %rdx, %r13      # move third argument color
        # calculate offset = ((y * x-resolution) + x) * (bpp / 8 )
        xorq    %rax, %rax      # zero rax
        movb    vesa_mode+25, %al # move bits per pixel
        movq    $0x08, %rbx     # set divisor to 8 
        xorq    %rdx, %rdx      # zero rdx
        divq    %rbx            # bits per pixel divided by divisor 
        movq    %rax, %r14      # keep interim result bytes per pixel
        movq    %r12, %rax      # set y
        movw    vesa_mode+18, %rbx # set x-resolution
        xorq    %rdx, %rdx      # zero rdx
        mulq    %rbx            # multiply y with x-resolution
        addq    %r11, %rax      # add x 
        xorq    %rdx, %rdx      # zero rdx
        mulq    %r14            # multiply with kept result 
        movq    vesa_mode+40, %rdi # move linear frame buffer address
        addq    %rax, %rdi      # add calculated offset
        movq    %r13, %rax      # set color
        stosq                   # store pixel
        popq    %r14            # restore r14 register from stack
        popq    %r13            # restore r13 register from stack
        popq    %r12            # restore r12 register from stack
        popq    %r11            # restore r11 register from stack
        popq    %rsi            # restore rsi register from stack
        popq    %rdi            # restore rdi register from stack
        popq    %rdx            # restore rdx register from stack
        popq    %rbx            # restore rbx register from stack
        popq    %rax            # restore rax register from stack
        leave                   # restore base pointer and stack pointer
        ret                     # return

# global descriptor table
gdtr32: .word 0x1F              # sizeof GDT 4 * 8 Bytes minus one 
        .long gdt               # address global descriptor table segments
gdtr64: .word 0x1F              # sizeof GDT 4 * 8 Bytes minus one 
        .quad gdt               # address global descriptor table segments
gdt:    .word 0,0,0,0           # null segment
        .word 0xffff,0x0000,0x9a00,0x00c0  # code segment 32 bit
        .word 0xffff,0x0000,0x9a00,0x00a0  # code segment 64 bit
        .word 0xffff,0x0000,0x9200,0x00c0  # data segment

# interrupt descriptor table
#idtr32: .word 0x                # sizeof IDT
#        .long idt               # address interrupt descriptor table segments
#idtr64: .word 0x                # sizeof IDT
#        .quad idt               # address interrupt descriptor table segments
#idt:

# e820 memory entry
e820:      .space 24            # e820 memory entry buffer

# vesa mode information
vesa_mode: .space 256           # vesa mode buffer

# ascii strings
error_cpu: .asciz "CPU error!\r\n"
error_memory: .asciz "Memory error!\r\n"
error_vesa: .asciz "VESA error!\r\n"
