# frozen_string_literal: false
require 'mkmf'

ok = true if RUBY_ENGINE == "ruby" || RUBY_ENGINE == "truffleruby"
hdr = nil
case
when macro_defined?("_WIN32", "")
  # rb_w32_map_errno: 1.8.7
  vk_header = File.exist?("#$srcdir/win32_vk.list") ? "chksum" : "inc"
  vk_header = "#{'{$(srcdir)}' if $nmake == ?m}win32_vk.#{vk_header}"
when hdr = %w"termios.h termio.h".find {|h| have_header(h)}
  have_func("cfmakeraw", hdr)
when have_header(hdr = "sgtty.h")
  %w"stty gtty".each {|f| have_func(f, hdr)}
else
  ok = false
end if ok
case ok
when true
  have_header("sys/ioctl.h") if hdr
  # rb_check_hash_type: 1.9.3
  # rb_io_get_write_io: 1.9.1
  # rb_cloexec_open: 2.0.0
  # rb_funcallv: 2.1.0
  # RARRAY_CONST_PTR: 2.1.0
  # rb_sym2str: 2.2.0
  if have_macro("HAVE_RUBY_FIBER_SCHEDULER_H")
    $defs << "-D""HAVE_RB_IO_WAIT=1"
  elsif have_func("rb_scheduler_timeout") # 3.0
    have_func("rb_io_wait")
  end
  $defs << "-D""ENABLE_IO_GETPASS=1"
  create_makefile("io/console") {|conf|
    conf << "\n""VK_HEADER = #{vk_header}\n"
  }
when nil
  File.write("Makefile", dummy_makefile($srcdir).join(""))
end
