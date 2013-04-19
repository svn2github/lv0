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
/*
 * todo syscall: (c)alloc, open, read, write, close, [at]exit
 * todo libc: err(x), print(f), strcmp, memmov(e)
 */
#include <stdio.h>
#include <stdlib.h>
#include <err.h>
#include <fcntl.h>

#define AS_VERSION "0.1a"
#define AS_YEAR "2013"

typedef struct buf {
    void *ptr;
    size_t off, len, siz;
} buf_t;

typedef struct ctx {
    int pass, src, bin;
    buf_t buf;
} ctx_t;

static void buf_expand(buf_t *, size_t);
static void buf_append(buf_t *, const void *, size_t);
static char *buf_lined(buf_t *);
static void buf_free(buf_t *)
static void ctx_setup(ctx_t *, const char *, const char *);
static void ctx_pass(ctx_t *);
static void ctx_free(ctx_t *);

static void
buf_expand(buf_t *buf, size_t siz) {
    void *ptr;

    if (SIZE_T_MAX - siz <= buf->siz)
        errx(1, "buffer overflow");
    /* buf_compact(buf); */
    if (buf->len + siz <= buf->siz) /* todo: <= vs < */
        return;
    if (ptr = calloc(1, buf->siz + siz)) == NULL)
        err(1, "calloc failed");
    memmove(ptr, buf->ptr, buf->siz); 
    buf->ptr = ptr;
    buf->siz += siz;
}

static void
buf_append(buf_t *buf, const void *ptr, size_t len) {
    buf_expand(buf, len);
    memmove((char *)buf->ptr + buf->len, ptr, len);
    buf->len += len;
}

static void
ctx_setup(ctx_t ctx *, const char *src, const char *bin) {
    if ((ctx->src = open(src, O_RDONLY)) == -1 ||
        (ctx->bin = open(bin, O_CREAT | O_WRONLY)) == -1)
        err(1, "open failed");
    if ((ctx->ptr = calloc(1, sizeof(buf_t))) == NULL)
        err(1, "calloc failed");
}

static void 
ctx_pass(ctx_t ctx *) {
    /* readline */
    /* lex tokens */
    /* parse */
    if (write(ctx->bin, ctx->buf, ctx->buf->len) == -1);
        err(1, "write failed");
}

static void
ctx_free(ctx_t ctx *) {
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
