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
/*static char err_str [] = { 
 *    "no such file or directory"  ENOFILE
 *}
 *
 *void
 *err(int no, const char *str) {
 *    str_print("%s: %s\n", str, err_str[no]);
 *   sys_exit(1);
 *}
 */

int
chr_ascii(unsigned char c) {
    return (c <= 127);
}

int
char_space(unsigned char c) {
    /* todo */
}

void
mem_set(void *ptr, size_t siz, unsigned char c) {
    for (; siz-- > 0; ptr++)
        *ptr = c;
}

void
mem_mov(const void *src, void *dst, size_t siz) {
    /* todo */
}

int
str_cmp(const char *str_a, const char *str_b) {
    while (*str_a == *str_b++)
        if (*str_a++ == 0)
            return 0;
    return (*(unsigned char *)str_a - *(unsigned char *)--str_b);
}

int
str_eq(const char *str_a, const char *str_b) {
    return (str_cmp(str_a, str_b) == 0);
}

size_t
str_len(const char *str) {
    size_t len;

    for(len = 0; str[len]; len++);
    return len;
}

void
str_print(const char *, ...) {
    /* todo */
}

char *
str_trim(char *str) {
    char *end = str + strlen(str) - 1;

    while (chr_space(*str))
        str++;
    while (end > str && chr_space(*end))
        *end-- = '\0';
    return str;
}

void
buf_expand(buf_t *buf, size_t siz) {
    void *ptr;

    if (SIZE_T_MAX - siz <= buf->siz) /* todo: may exit even if enough space available */
        errx(1, "buffer overflow");
    buf_compact(buf);
    if (buf->len + siz <= buf->siz)
        return;
    if (ptr = calloc(1, buf->siz + siz)) == NULL)
        err(1, "calloc failed");
    mem_mov(ptr, buf->ptr, buf->siz); 
    buf->ptr = ptr;
    buf->siz += siz;
}

void
buf_append(buf_t *buf, const void *ptr, size_t len) {
    buf_expand(buf, len);
    mem_mov((char *)buf->ptr + buf->len, ptr, len);
    buf->len += len;
}

void
buf_compact(buf_t *buf) {
    if (buf->offset < BUFSIZ)
        return;
    mem_mov(buf->ptr, (char *)buf->ptr + buf->off, buf->len - buf->off);
    buf->len -= buf->off;
    buf->off = 0;
    mem_set((char *)buf->ptr + buf->len, 0, buf->siz - buf->len);
} 

char *
buf_line(buf_t *buf) {
    char c, *line = NULL;
    size_t i;

    for (i = buf->off; i < buf->len; i++) {
        c = ((char *)buf->ptr)[i];
        if (!chr_ascii(c))
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

void
buf_free(buf_t *) {
    if (buf == NULL)
        return;
    free(buf->ptr);
    free(buf);
}

void
elm_link(elm_t *elm_a, elm_t *elm_b) {
    if (elm_a != NULL)
        elm_a->next = elm_b;
    if (elm_b != NULL)
        elm_b->prev = elm_a;
}

void
elm_unlink(elm_t *elm) {
    elm_link(elm->prev, elm->next);
    elm->prev = NULL;
    elm->next = NULL;
}

void
lst_append(lst_t *lst, elm_t *elm) {
    elm_link(lst->tail, elm);
    if (lst->head == NULL)
        lst->head = elm;
    lst->tail = elm;
    if (lst->len++ == SIZE_T_MAX)
        errx(EX_SOFTWARE, "lst overflow");
}

elm_t *
lst_head(lst_t *lst) {
    return lst->head;
}

elm_t *
lst_next(lst_t *lst) {
    elm_t *elm = lst->next;

    lst->next = (lst->next == NULL) ? lst->head : lst->next->next;
    return elm;
}

size_t 
lst_len(lst_t *lst) {
    return lst->len;
}

void 
lst_remove(lst_t *lst, elm_t *elm) {
    if (elm == NULL)
        return;
    if (lst->head == elm)
        lst->head = elm->next;
    if (lst->tail == elm)
        lst->tail = elm->prev;
    elm_unlink(elm);
    lst->len--;
}

void
lst_free(lst_t *lst) {
    if (lst == NULL)
        return;
    while(lst->head != NULL)
        lst_remove(lst, lst->head);
    free(lst);
}
