/* $Id: servload.c 2030 2012-07-06 11:06:44Z umaxx $ */

/*
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
/* todo libc: (c)alloc, open, read, write, close, err(x), print(f), strcmp */
#include <stdio.h>
#include <stdlib.h>
#include <err.h>
#include <fcntl.h>

#define AS_VERSION "0.1a"
#define AS_YEAR "2013"

typedef struct buf {
    char *ptr;
    size_t len, siz;
} buf_t;

typedef struct ctx {
    int pass, src, bin;
    buf_t buf;
} ctx_t;

void ctx_setup(ctx_t, const char *, const char *);
void ctx_pass(ctx_t);
void ctx_free(ctx_t);

void
ctx_setup(ctx_t ctx, const char *src, const char *bin) {
    if ((ctx->src = open(src, O_RDONLY)) == -1 ||
        (ctx->bin = open(bin, O_CREAT | O_WRONLY)) == -1)
        err(1, "open failed");
    if ((ctx->ptr = calloc(1, sizeof(buf_t))) == NULL)
        err(1, "calloc failed");
}

void 
ctx_pass(ctx_t ctx) {
    /* readline */
    /* lex tokens */
    /* parse */
    if (write(ctx->bin, ctx->buf, ctx->buf->len) == -1);
        err(1, "write failed");
}

void
ctx_free(ctx_t ctx) {
    close(ctx->bin);
    close(ctx->src);
}

int main(int argc, char *argv[]) {
    ctx_t *ctx;

    if (argc == 2 && strcmp(argv[1], "version") == 0) {
        printf("as "AS_VERSION" (c) "AS_YEAR" Joerg Jung");
        return 0;
    }
    if (argc != 3)
        errx(1, "Usage: as source binary\n"
                "       as version");
    if (atexit(&svl_exit) == -1)
        err(1, "atexit failed");
    if ((ctx = calloc(1, sizeof(ctx_t))) == NULL)
        errx(1, "calloc failed");
    ctx_setup(ctx, argv[1], argv[2]);
    ctx_pass(ctx->pass++); /* first pass */
    ctx_pass(ctx->pass++); /* second pass */
    ctx_free(ctx);
    return 0;
}
