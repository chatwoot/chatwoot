# frozen_string_literal: true
require 'mkmf'

have_func("rb_enc_interned_str", "ruby/encoding.h") # RUBY_VERSION >= 3.0
have_func("rb_hash_new_capa", "ruby.h") # RUBY_VERSION >= 3.2
have_func("rb_hash_bulk_insert", "ruby.h") # Missing on TruffleRuby
have_func("strnlen", "string.h") # Missing on Solaris 10

append_cflags("-std=c99")

if enable_config('parser-use-simd', default=!ENV["JSON_DISABLE_SIMD"])
  load __dir__ + "/../simd/conf.rb"
end

create_makefile 'json/ext/parser'
