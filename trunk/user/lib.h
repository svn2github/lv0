/* $Id: servload.c 2030 2012-07-06 11:06:44Z umaxx $
 *
 * Copyright (c) 2013 Joerg Jung <umaxx@lv0.org>
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
#define NULL 0

enum { BUF_SIZ = 4096 };

typedef unsigned long size_t;

typedef struct buf {
    void *ptr;
    size_t off, len, siz;
} buf_t;

typedef struct elm {
    struct elm *next, *prev;
} elm_t;

typedef struct lst {
    elm_t *head, *tail, *next;
    size_t len;
} lst_t;

int chr_ascii(unsigned char);
int chr_space(unsigned char);
void mem_set(void *, size_t, unsigned char);
void mem_mov(const void *, void *, size_t);
void str_print(const char *, ...);
int str_cmp(const char *, const char *);
int str_eq(const char *, const char *);
size_t str_len(const char *);
char *str_trim(char *);
void buf_expand(buf_t *, size_t);
void buf_append(buf_t *, const void *, size_t);
char *buf_line(buf_t *);
void buf_compact(buf_t *);
void buf_free(buf_t *)
void elm_link(elm_t *);
void elm_unlink(elm_t *);
void lst_append(lst_t *, elm_t *);
void lst_remove(lst_t *, elm_t *);
void *lst_first(lst_t *);
voif *lst_next(lst_t *);
size_t lst_len(lst_t *);

pid_t sys_fork(void);
int sys_signal(pid_t, int);
void sys_atexit(void (*cb)(void *)); /* todo: better name */
void sys_exit(int);
void *sys_alloc(size_t);
void sys_free(void *);
int sys_open(char *, int);
int sys_read(int, void *, size_t);
int sys_write(int, void *, size_t);
void sys_close(int);
