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

# cd boot sector expecting no emulation and a sector size of 2048 bytes
# bios loads this code at physical address 0x7c00-0x7d00 (512 bytes)
.code16                         # start in 16 bit real mode

.set BIOS_DISK, 0x13            # bios low level disk services interrupt
.set BIOS_VIDEO, 0x10           # bios video services interrupt

# linker entry point of bootsector
.global _start
_start:
        cli                     # disable interrupts
        cld                     # clear direction flag for string operations
        xorw    %ax, %ax        # zero ax
        movw    %ax, %ds        # setup the data segment
        movw    %ax, %es        # setup the extra segment
        movw    %ax, %ss        # setup the stack segment
        movw    $_start, %sp    # set stack pointer to 0x7c00 growing downwards
        movb    %dl, drive      # save boot drive number 
        movw    $0x0003, %ax    # video mode 80x25 and 16 color and clear screen
        int     $BIOS_VIDEO     # call bios video function
        movw    $message, %si   # set message
        call    print           # print message
        # todo: reset disk drive int 0x13 ah 00 dl drive

# sectors 0x00-0x0F of iso9960 are reserved for system use
# the volume descriptors can be found starting at sector 0x10
        movl    $0x10, %eax     # set first volume descriptor

# read volume descriptors until primary is found
# volume descriptor is moved to temporary memory position 0x1000 (4k)
descriptor:
        movb    $1, %dh         # set number of sectors to read
        movw    $0x1000, %bx    # set volume descriptor destination
        call    read            # read sector
        cmpb    $1, (%bx)       # check if primary volume descriptor 1
        jz      root            # found primary volume descriptor
        incl    %eax            # try next descriptor
        cmpb    $255, (%bx)     # check if termination descriptor 255
        jnz     descriptor      # next volume descriptor
        movw    $error_primary, %si # set error message
        call    print           # print message
        hlt                     # halt

# read root directory entry from primary volume descriptor 
# ignore path table to avoid limited number of entries restriction
# the root directory entry address can be found starting at offset 156
# root directory entry is moved to temporary memory position 0x1000 (4k) too
root:
        movw    $0x1000+156, %bx # set root directory adddress from
                                 # primary volume descriptor
        movl    2(%bx), %eax    # set sector of root directory extent
                                # from offset 2 of root directory entry
        movl    10(%bx), %edx   # set size of extent from offset 10 of 
                                # root directory entry
        shrl    $11, %edx       # size of extent didvided by sector size 
                                # 2^11 = 2048 results in sector count
        movb    %dl, %dh        # set calculated sector count
        movw    $0x1000, %bx    # set root directory destination
        call    read            # read sector

# read root directory extents and compare extents filenames with kernel 
# image name lv0.bin until filename match
# directory extents can be further directories or files
extent:
        cmpb    $0, 0(%bx)      # compare length of the loaded extent from offset 0 
        jz      extent_error    # last entry found
        #bt      $1, 25(%bx)     # test bit 1 of loaded extent file flags
        #                        # at offset 25 specifying the type
        #jc      extent.next     # ignore directory if bit 1 is set
        movw    $filename, %si  # set kernel filename to si
        movw    %bx, %di        # move extent to di
        addw    $33, %di        # add offset 33 of filename to di  
        movb    32(%bx), %cl    # add filename length to cl from offset 32
        repe                    # repeat comparison while equal
        cmpsb                   # compare string bytes 
        je kernel               # kernel filename found
extent_next:
        addw    0(%bx), %bx     # add length of current entry
        jmp extent              # move on with next entry
extent_error:
        movw    $error_extent, %si # set error message
        call    print           # print message
        hlt                     # halt

# load kernel file to address 0x8000 (32k)
kernel: 
        movl    2(%bx), %eax    # set source sector of kernel file from offset 2 
        movl    10(%bx), %edx   # set size of kernel file extent from 
                                # offset 10 of kernel entry
    addl    $(2047), %edx   # convert file length to
    shrl    $11, %edx       #  ... number of sectors
    movb    %dl, %dh
    #movb    $1, %dh
        movw    $0x8000, %bx    # set kernel destination addresss
        call    read            # read kernel file
        ljmp    $0, $0x8000     # run the kernel at segment offset
 
# extended read sectors from drive
# load dh sectors starting at lba eax to es:bx
read:
        enter   $0, $0          # handle base pointer and stack pointer
        movl    %eax, packet_start # start sector
        movw    %es, packet_segment # set destination address segment
        movw    %bx, packet_offset # set destination address offset
        movb    %dh, packet_count # number of sectors to read
read_retry:
        movb    drive, %dl      # bios device drive
        movw    $packet, %si    # disk address packet
        movb    $0x42, %ah      # bios extended read
        int     $BIOS_DISK      # call extended read function
        jc      read_fail       # check read result
        leave                   # restore base pointer and stack pointer
        ret                     # return        
read_fail:        
        cmp     $0x80, %ah      # check for bios timeout
        je      read_retry      # timed out retry
read_error:
        movw    $error_read, %si # set error read message
        call    print           # print message
        hlt                     # halt
        
# print null terminated string to video
print:
        enter   $0, $0          # handle base pointer and stack pointer
print_character:
        lodsb                   # read character
        cmpb    $0, %al         # check if end of string reached
        je      print_done      # nothing more to print
        movb    $0x0e, %ah      # display character on screen
        movw    $0x07, %bx      # page 0 and color white
        int     $BIOS_VIDEO     # call bios video function
        jmp     print_character # loop until end of string is reached
print_done:
        leave                   # restore base pointer and stack pointer
        ret                     # return

# boot drive
drive: .byte 0

# disk address packet
packet:
packet_size:    .byte 0x10, 0   # size of disk address packet
packet_count:   .byte 0, 0      # number of sectors to read
packet_offset:  .word 0         # destination address offset
packet_segment: .word 0         # destination address segment
packet_start:   .quad 0         # start sector

# ascii strings
filename:       .asciz "lv0.bin;1"
message:        .asciz "Loading /lv0.bin...\r\n"
error_read:     .asciz "Read error!\r\n"
error_primary:  .asciz "Primary volume descriptor not found!\r\n"
error_extent:   .asciz "File /lv0.bin not found!\r\n"

.org 2046
.word 0xaa55                    # boot signature
