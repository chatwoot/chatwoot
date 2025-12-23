#include <ruby.h>

VALUE method_websocket_mask(VALUE self, VALUE payload, VALUE mask)
{
    char *payload_s, *mask_s, *unmasked_s;
    long i, n;
    VALUE unmasked;

    if (mask == Qnil || RSTRING_LEN(mask) != 4) {
        return payload;
    }

    payload_s = RSTRING_PTR(payload);
    mask_s    = RSTRING_PTR(mask);
    n         = RSTRING_LEN(payload);

    unmasked   = rb_str_new(0, n);
    unmasked_s = RSTRING_PTR(unmasked);

    for (i = 0; i < n; i++) {
        unmasked_s[i] = payload_s[i] ^ mask_s[i % 4];
    }
    return unmasked;
}

void Init_websocket_mask()
{
    VALUE WebSocket = rb_define_module("WebSocket");
    VALUE Mask = rb_define_module_under(WebSocket, "Mask");

    rb_define_singleton_method(Mask, "mask", method_websocket_mask, 2);
}
