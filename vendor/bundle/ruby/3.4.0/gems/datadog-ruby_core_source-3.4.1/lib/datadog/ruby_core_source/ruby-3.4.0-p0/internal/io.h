#ifndef INTERNAL_IO_H                                    /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_IO_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for IO.
 */
#include "ruby/ruby.h"          /* for VALUE */

#define HAVE_RB_IO_T
struct rb_io;

#include "ruby/io.h"            /* for rb_io_t */

#define IO_WITHOUT_GVL(func, arg) rb_nogvl(func, arg, RUBY_UBF_IO, 0, RB_NOGVL_OFFLOAD_SAFE)
#define IO_WITHOUT_GVL_INT(func, arg) (int)(VALUE)IO_WITHOUT_GVL(func, arg)

/** Ruby's IO, metadata and buffers. */
struct rb_io {

    /** The IO's Ruby level counterpart. */
    VALUE self;

    /** stdio ptr for read/write, if available. */
    FILE *stdio_file;

    /** file descriptor. */
    int fd;

    /** mode flags: FMODE_XXXs */
    int mode;

    /** child's pid (for pipes) */
    rb_pid_t pid;

    /** number of lines read */
    int lineno;

    /** pathname for file */
    VALUE pathv;

    /** finalize proc */
    void (*finalize)(struct rb_io*,int);

    /** Write buffer. */
    rb_io_buffer_t wbuf;

    /**
     * (Byte)  read   buffer.   Note  also   that  there  is  a   field  called
     * ::rb_io_t::cbuf, which also concerns read IO.
     */
    rb_io_buffer_t rbuf;

    /**
     * Duplex IO object, if set.
     *
     * @see rb_io_set_write_io()
     */
    VALUE tied_io_for_writing;

    struct rb_io_encoding encs; /**< Decomposed encoding flags. */

    /** Encoding converter used when reading from this IO. */
    rb_econv_t *readconv;

    /**
     * rb_io_ungetc()  destination.   This  buffer   is  read  before  checking
     * ::rb_io_t::rbuf
     */
    rb_io_buffer_t cbuf;

    /** Encoding converter used when writing to this IO. */
    rb_econv_t *writeconv;

    /**
     * This is, when set, an instance  of ::rb_cString which holds the "common"
     * encoding.   Write  conversion  can  convert strings  twice...   In  case
     * conversion from encoding  X to encoding Y does not  exist, Ruby finds an
     * encoding Z that bridges the two, so that X to Z to Y conversion happens.
     */
    VALUE writeconv_asciicompat;

    /** Whether ::rb_io_t::writeconv is already set up. */
    int writeconv_initialized;

    /**
     * Value   of    ::rb_io_t::rb_io_enc_t::ecflags   stored    right   before
     * initialising ::rb_io_t::writeconv.
     */
    int writeconv_pre_ecflags;

    /**
     * Value of ::rb_io_t::rb_io_enc_t::ecopts stored right before initialising
     * ::rb_io_t::writeconv.
     */
    VALUE writeconv_pre_ecopts;

    /**
     * This is a Ruby  level mutex.  It avoids multiple threads  to write to an
     * IO at  once; helps  for instance rb_io_puts()  to ensure  newlines right
     * next to its arguments.
     *
     * This of course doesn't help inter-process IO interleaves, though.
     */
    VALUE write_lock;

    /**
     * The timeout associated with this IO when performing blocking operations.
     */
    VALUE timeout;
};

/* io.c */
void ruby_set_inplace_mode(const char *);
void rb_stdio_set_default_encoding(void);
VALUE rb_io_flush_raw(VALUE, int);
size_t rb_io_memsize(const rb_io_t *);
int rb_stderr_tty_p(void);
void rb_io_fptr_finalize_internal(void *ptr);
#ifdef rb_io_fptr_finalize
# undef rb_io_fptr_finalize
#endif
#define rb_io_fptr_finalize rb_io_fptr_finalize_internal
VALUE rb_io_popen(VALUE pname, VALUE pmode, VALUE env, VALUE opt);

VALUE rb_io_prep_stdin(void);
VALUE rb_io_prep_stdout(void);
VALUE rb_io_prep_stderr(void);

RUBY_SYMBOL_EXPORT_BEGIN
/* io.c (export) */
void rb_maygvl_fd_fix_cloexec(int fd);
int rb_gc_for_fd(int err);
void rb_write_error_str(VALUE mesg);

VALUE rb_io_blocking_region_wait(struct rb_io *io, rb_blocking_function_t *function, void *argument, enum rb_io_event events);
VALUE rb_io_blocking_region(struct rb_io *io, rb_blocking_function_t *function, void *argument);
RUBY_SYMBOL_EXPORT_END

#endif /* INTERNAL_IO_H */
