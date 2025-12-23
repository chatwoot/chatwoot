#ifndef INTERNAL_RACTOR_H                                /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_RACTOR_H

void rb_ractor_ensure_main_ractor(const char *msg);

RUBY_SYMBOL_EXPORT_BEGIN
void rb_ractor_setup_belonging(VALUE obj);
RUBY_SYMBOL_EXPORT_END

#endif /* INTERNAL_RACTOR_H */
