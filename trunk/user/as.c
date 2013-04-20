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
/*
 * todo syscall: (c)alloc, free, open, read, write, close, [at]exit
 * todo lib: buf/BUF_SIZ, err(x), print(f), str(_)cmp, str(_)len, str_trim, 
 *           (mem)move, (mem)set(zero), (is)ascii, (is)space
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <err.h>
#include <fcntl.h>
#include <sys/types.h>
#include <unistd.h>

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

static char *str_trim(char *);
static void buf_expand(buf_t *, size_t);
static void buf_append(buf_t *, const void *, size_t);
static char *buf_lined(buf_t *);
static void buf_compact(buf_t *);
static void buf_free(buf_t *)
static void ctx_setup(ctx_t *, const char *, const char *);
static void ctx_pass(ctx_t *);
static void ctx_free(ctx_t *);

static char *
str_trim(char *str) {
    char *end = str + strlen(str) - 1;

    while (isspace(*str))
        str++;
    while (end > str && isspace(*end))
        *end-- = '\0';
    return str;
}

static void
buf_expand(buf_t *buf, size_t siz) {
    void *ptr;

    if (SIZE_T_MAX - siz <= buf->siz) /* todo: may exit even if enough space available */
        errx(1, "buffer overflow");
    buf_compact(buf);
    if (buf->len + siz <= buf->siz)
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
buf_compact(buf_t *buf) {
    if (buf->offset < BUFSIZ)
        return;
    memmove(buf->ptr, (char *)buf->ptr + buf->off, buf->len - buf->off);
    buf->len -= buf->off;
    buf->off = 0;
    memset((char *)buf->ptr + buf->len, 0, buf->siz - buf->len);
} 

static char *
buf_line(buf_t *buf) {
    char c, *line = NULL;
    size_t i;

    for (i = buf->off; i < buf->len; i++) {
        c = ((char *)buf->ptr)[i];
        if (!isascii((int)c))
            errx(1, "invalid character");
        if (c == '\n') {
            ((char *)buf->ptr)[i] = '\0';
            line = &((char *)buf->ptr)[buf->off];
            buf->off = i + 1;
            break;
        }
    }
    return line;
}

static void
buf_free(buf_t *) {
    if (buf == NULL)
        return;
    free(buf->ptr);
    free(buf);
}

static void
ctx_setup(ctx_t ctx *, const char *src, const char *bin) {
    if ((ctx->src = open(src, O_RDONLY)) == -1 ||
        (ctx->bin = open(bin, O_CREAT | O_WRONLY)) == -1)
        err(1, "open failed");
    if ((ctx->buf = calloc(1, sizeof(buf_t))) == NULL)
        err(1, "calloc failed");
}

static void 
ctx_pass(ctx_t ctx *) {
    ssize_t r;
    char *line;

    ctx->pass++;
    while(fds_read(fds) > 0) {
        while ((line = buf_line(ctx->buf)) != NULL) {
            line = str_trim(line);  
            /* lex tokens */
            /* parse */
        }
    }
    if (write(ctx->bin, ctx->buf, ctx->buf->len) == -1);
        err(1, "write failed");
}

static void
ctx_free(ctx_t ctx *) {
    if (ctx == NULL)
        return;
    buf_free(ctx->buf);
    close(ctx->bin);
    close(ctx->src);
    free(ctx);
}

static void
ctx_exit(void) {
    ctx_free(ctx);
    ctx = NULL;
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
    if (atexit(&ctx_exit) == -1)
        err(1, "atexit failed");
    if ((ctx = calloc(1, sizeof(ctx_t))) == NULL)
        errx(1, "calloc failed");
    ctx_setup(ctx, argv[1], argv[2]);
    ctx_pass(ctx); /* first pass */
    ctx_pass(ctx); /* second pass */
    ctx_free(ctx);
    return 0;
}
