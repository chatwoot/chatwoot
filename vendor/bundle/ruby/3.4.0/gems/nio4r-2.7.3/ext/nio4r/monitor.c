/*
 * Copyright (c) 2011 Tony Arcieri. Distributed under the MIT License. See
 * LICENSE.txt for further details.
 */

#include "nio4r.h"
#include <assert.h>

static VALUE mNIO = Qnil;
static VALUE cNIO_Monitor = Qnil;

/* Allocator/deallocator */
static VALUE NIO_Monitor_allocate(VALUE klass);
static void NIO_Monitor_mark(void *data);
static size_t NIO_Monitor_memsize(const void *data);

/* Methods */
static VALUE NIO_Monitor_initialize(VALUE self, VALUE selector, VALUE io, VALUE interests);
static VALUE NIO_Monitor_close(int argc, VALUE *argv, VALUE self);
static VALUE NIO_Monitor_is_closed(VALUE self);
static VALUE NIO_Monitor_io(VALUE self);
static VALUE NIO_Monitor_interests(VALUE self);
static VALUE NIO_Monitor_set_interests(VALUE self, VALUE interests);
static VALUE NIO_Monitor_add_interest(VALUE self, VALUE interest);
static VALUE NIO_Monitor_remove_interest(VALUE self, VALUE interest);
static VALUE NIO_Monitor_selector(VALUE self);
static VALUE NIO_Monitor_is_readable(VALUE self);
static VALUE NIO_Monitor_is_writable(VALUE self);
static VALUE NIO_Monitor_value(VALUE self);
static VALUE NIO_Monitor_set_value(VALUE self, VALUE obj);
static VALUE NIO_Monitor_readiness(VALUE self);

/* Internal C functions */
static int NIO_Monitor_symbol2interest(VALUE interests);
static void NIO_Monitor_update_interests(VALUE self, int interests);

/* Compatibility for Ruby <= 3.1 */
#ifndef HAVE_RB_IO_DESCRIPTOR
static int
io_descriptor_fallback(VALUE io)
{
    rb_io_t *fptr;
    GetOpenFile(io, fptr);
    return fptr->fd;
}
#define rb_io_descriptor io_descriptor_fallback
#endif

/* Monitor control how a channel is being waited for by a monitor */
void Init_NIO_Monitor()
{
    mNIO = rb_define_module("NIO");
    cNIO_Monitor = rb_define_class_under(mNIO, "Monitor", rb_cObject);
    rb_define_alloc_func(cNIO_Monitor, NIO_Monitor_allocate);

    rb_define_method(cNIO_Monitor, "initialize", NIO_Monitor_initialize, 3);
    rb_define_method(cNIO_Monitor, "close", NIO_Monitor_close, -1);
    rb_define_method(cNIO_Monitor, "closed?", NIO_Monitor_is_closed, 0);
    rb_define_method(cNIO_Monitor, "io", NIO_Monitor_io, 0);
    rb_define_method(cNIO_Monitor, "interests", NIO_Monitor_interests, 0);
    rb_define_method(cNIO_Monitor, "interests=", NIO_Monitor_set_interests, 1);
    rb_define_method(cNIO_Monitor, "add_interest", NIO_Monitor_add_interest, 1);
    rb_define_method(cNIO_Monitor, "remove_interest", NIO_Monitor_remove_interest, 1);
    rb_define_method(cNIO_Monitor, "selector", NIO_Monitor_selector, 0);
    rb_define_method(cNIO_Monitor, "value", NIO_Monitor_value, 0);
    rb_define_method(cNIO_Monitor, "value=", NIO_Monitor_set_value, 1);
    rb_define_method(cNIO_Monitor, "readiness", NIO_Monitor_readiness, 0);
    rb_define_method(cNIO_Monitor, "readable?", NIO_Monitor_is_readable, 0);
    rb_define_method(cNIO_Monitor, "writable?", NIO_Monitor_is_writable, 0);
    rb_define_method(cNIO_Monitor, "writeable?", NIO_Monitor_is_writable, 0);
}

static const rb_data_type_t NIO_Monitor_type = {
    "NIO::Monitor",
    {
        NIO_Monitor_mark,
        RUBY_TYPED_DEFAULT_FREE,
        NIO_Monitor_memsize,
    },
    0,
    0,
    RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED
};

static VALUE NIO_Monitor_allocate(VALUE klass)
{
    struct NIO_Monitor *monitor = (struct NIO_Monitor *)xmalloc(sizeof(struct NIO_Monitor));
    assert(monitor);
    *monitor = (struct NIO_Monitor){.self = Qnil};
    return TypedData_Wrap_Struct(klass, &NIO_Monitor_type, monitor);
}

static void NIO_Monitor_mark(void *data)
{
    struct NIO_Monitor *monitor = (struct NIO_Monitor *)data;
    rb_gc_mark(monitor->self);
}

static size_t NIO_Monitor_memsize(const void *data)
{
    const struct NIO_Monitor *monitor = (const struct NIO_Monitor *)data;
    return sizeof(*monitor);
}

static VALUE NIO_Monitor_initialize(VALUE self, VALUE io, VALUE interests, VALUE selector_obj)
{
    struct NIO_Monitor *monitor;
    struct NIO_Selector *selector;
    ID interests_id;

    interests_id = SYM2ID(interests);

    TypedData_Get_Struct(self, struct NIO_Monitor, &NIO_Monitor_type, monitor);

    if (interests_id == rb_intern("r")) {
        monitor->interests = EV_READ;
    } else if (interests_id == rb_intern("w")) {
        monitor->interests = EV_WRITE;
    } else if (interests_id == rb_intern("rw")) {
        monitor->interests = EV_READ | EV_WRITE;
    } else {
        rb_raise(rb_eArgError, "invalid event type %s (must be :r, :w, or :rw)", RSTRING_PTR(rb_funcall(interests, rb_intern("inspect"), 0)));
    }

    int descriptor = rb_io_descriptor(rb_convert_type(io, T_FILE, "IO", "to_io"));
    ev_io_init(&monitor->ev_io, NIO_Selector_monitor_callback, descriptor, monitor->interests);

    rb_ivar_set(self, rb_intern("io"), io);
    rb_ivar_set(self, rb_intern("interests"), interests);
    rb_ivar_set(self, rb_intern("selector"), selector_obj);

    selector = NIO_Selector_unwrap(selector_obj);

    RB_OBJ_WRITE(self, &monitor->self, self);
    monitor->ev_io.data = (void *)monitor;

    /* We can safely hang onto this as we also hang onto a reference to the
       object where it originally came from */
    monitor->selector = selector;

    if (monitor->interests) {
        ev_io_start(selector->ev_loop, &monitor->ev_io);
    }

    return Qnil;
}

static VALUE NIO_Monitor_close(int argc, VALUE *argv, VALUE self)
{
    VALUE deregister, selector;
    struct NIO_Monitor *monitor;
    TypedData_Get_Struct(self, struct NIO_Monitor, &NIO_Monitor_type, monitor);

    rb_scan_args(argc, argv, "01", &deregister);
    selector = rb_ivar_get(self, rb_intern("selector"));

    if (selector != Qnil) {
        /* if ev_loop is 0, it means that the loop has been stopped already (see NIO_Selector_shutdown) */
        if (monitor->interests && monitor->selector->ev_loop) {
            ev_io_stop(monitor->selector->ev_loop, &monitor->ev_io);
        }

        monitor->selector = 0;
        rb_ivar_set(self, rb_intern("selector"), Qnil);

        /* Default value is true */
        if (deregister == Qtrue || deregister == Qnil) {
            rb_funcall(selector, rb_intern("deregister"), 1, rb_ivar_get(self, rb_intern("io")));
        }
    }

    return Qnil;
}

static VALUE NIO_Monitor_is_closed(VALUE self)
{
    struct NIO_Monitor *monitor;
    TypedData_Get_Struct(self, struct NIO_Monitor, &NIO_Monitor_type, monitor);

    return monitor->selector == 0 ? Qtrue : Qfalse;
}

static VALUE NIO_Monitor_io(VALUE self)
{
    return rb_ivar_get(self, rb_intern("io"));
}

static VALUE NIO_Monitor_interests(VALUE self)
{
    return rb_ivar_get(self, rb_intern("interests"));
}

static VALUE NIO_Monitor_set_interests(VALUE self, VALUE interests)
{
    if (NIL_P(interests)) {
        NIO_Monitor_update_interests(self, 0);
    } else {
        NIO_Monitor_update_interests(self, NIO_Monitor_symbol2interest(interests));
    }

    return rb_ivar_get(self, rb_intern("interests"));
}

static VALUE NIO_Monitor_add_interest(VALUE self, VALUE interest)
{
    struct NIO_Monitor *monitor;
    TypedData_Get_Struct(self, struct NIO_Monitor, &NIO_Monitor_type, monitor);

    interest = monitor->interests | NIO_Monitor_symbol2interest(interest);
    NIO_Monitor_update_interests(self, (int)interest);

    return rb_ivar_get(self, rb_intern("interests"));
}

static VALUE NIO_Monitor_remove_interest(VALUE self, VALUE interest)
{
    struct NIO_Monitor *monitor;
    TypedData_Get_Struct(self, struct NIO_Monitor, &NIO_Monitor_type, monitor);

    interest = monitor->interests & ~NIO_Monitor_symbol2interest(interest);
    NIO_Monitor_update_interests(self, (int)interest);

    return rb_ivar_get(self, rb_intern("interests"));
}

static VALUE NIO_Monitor_selector(VALUE self)
{
    return rb_ivar_get(self, rb_intern("selector"));
}

static VALUE NIO_Monitor_value(VALUE self)
{
    return rb_ivar_get(self, rb_intern("value"));
}

static VALUE NIO_Monitor_set_value(VALUE self, VALUE obj)
{
    return rb_ivar_set(self, rb_intern("value"), obj);
}

static VALUE NIO_Monitor_readiness(VALUE self)
{
    struct NIO_Monitor *monitor;
    TypedData_Get_Struct(self, struct NIO_Monitor, &NIO_Monitor_type, monitor);

    if ((monitor->revents & (EV_READ | EV_WRITE)) == (EV_READ | EV_WRITE)) {
        return ID2SYM(rb_intern("rw"));
    } else if (monitor->revents & EV_READ) {
        return ID2SYM(rb_intern("r"));
    } else if (monitor->revents & EV_WRITE) {
        return ID2SYM(rb_intern("w"));
    } else {
        return Qnil;
    }
}

static VALUE NIO_Monitor_is_readable(VALUE self)
{
    struct NIO_Monitor *monitor;
    TypedData_Get_Struct(self, struct NIO_Monitor, &NIO_Monitor_type, monitor);

    if (monitor->revents & EV_READ) {
        return Qtrue;
    } else {
        return Qfalse;
    }
}

static VALUE NIO_Monitor_is_writable(VALUE self)
{
    struct NIO_Monitor *monitor;
    TypedData_Get_Struct(self, struct NIO_Monitor, &NIO_Monitor_type, monitor);

    if (monitor->revents & EV_WRITE) {
        return Qtrue;
    } else {
        return Qfalse;
    }
}

/* Internal C functions */

static int NIO_Monitor_symbol2interest(VALUE interests)
{
    ID interests_id;
    interests_id = SYM2ID(interests);

    if (interests_id == rb_intern("r")) {
        return EV_READ;
    } else if (interests_id == rb_intern("w")) {
        return EV_WRITE;
    } else if (interests_id == rb_intern("rw")) {
        return EV_READ | EV_WRITE;
    } else {
        rb_raise(rb_eArgError, "invalid interest type %s (must be :r, :w, or :rw)", RSTRING_PTR(rb_funcall(interests, rb_intern("inspect"), 0)));
    }
}

static void NIO_Monitor_update_interests(VALUE self, int interests)
{
    ID interests_id;
    struct NIO_Monitor *monitor;
    TypedData_Get_Struct(self, struct NIO_Monitor, &NIO_Monitor_type, monitor);

    if (NIO_Monitor_is_closed(self) == Qtrue) {
        rb_raise(rb_eEOFError, "monitor is closed");
    }

    if (interests) {
        switch (interests) {
            case EV_READ:
                interests_id = rb_intern("r");
                break;
            case EV_WRITE:
                interests_id = rb_intern("w");
                break;
            case EV_READ | EV_WRITE:
                interests_id = rb_intern("rw");
                break;
            default:
                rb_raise(rb_eRuntimeError, "bogus NIO_Monitor_update_interests! (%d)", interests);
        }

        rb_ivar_set(self, rb_intern("interests"), ID2SYM(interests_id));
    } else {
        rb_ivar_set(self, rb_intern("interests"), Qnil);
    }

    if (monitor->interests != interests) {
        // If the monitor currently has interests, we should stop it.
        if (monitor->interests) {
            ev_io_stop(monitor->selector->ev_loop, &monitor->ev_io);
        }

        // Assign the interests we are now monitoring for:
        monitor->interests = interests;
        ev_io_set(&monitor->ev_io, monitor->ev_io.fd, monitor->interests);

        // If we are interested in events, schedule the monitor back into the event loop:
        if (monitor->interests) {
            ev_io_start(monitor->selector->ev_loop, &monitor->ev_io);
        }
    }
}
