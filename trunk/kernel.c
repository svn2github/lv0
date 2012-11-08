/* $Id: servload.c 2030 2012-07-06 11:06:44Z umaxx $ */

/*
 * Copyright (c) 2012 Joerg Zinke <umaxx@lv0.org>
 *
 * Permission to use, copy, modify, and distribute this software for any purpose
 * with or without fee is hereby granted, provided that the above copyright 
 * notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
 * REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
 * INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
 * LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
 * OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 */
void pixel(unsigned short, unsigned short, unsigned int);
void main(void);

static void character(unsigned char);
static void print(const char *);

static void
character(unsigned char value) {
    /* print 8x8 bitmap character to video using pixel and to serial */
}

static void
print(const char *string) {
    while (*string != '\0')
        character(*string++);
}

void 
main(void) {
    unsigned short x=200, i;
    pixel(5, 5, 0xff0000);
    pixel(10, 10, 0x0000ff);
    for (i = 0; i < 100; i++) {
	/*x++;*/
        pixel(x, 100, 0xff0000);
    }
    print("lv0: Hello World!");
}
