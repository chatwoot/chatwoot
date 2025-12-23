if RUBY_PLATFORM == "java"
  # Don't do anything when run in JRuby; this allows gem installation to pass.
  # We need to write a dummy Makefile so that RubyGems doesn't think compilation
  # failed.
  File.open('Makefile', 'w') do |f|
    f.puts "all:"
    f.puts "\t@true"
    f.puts "install:"
    f.puts "\t@true"
  end
  exit 0
else
  require "mkmf"

  # From Openwall's crypt_blowfish Makefile.
  # This is `bcrypt_ext` (our extension) + CRYPT_OBJS from that Makefile.
  $objs = %w(bcrypt_ext.o crypt_blowfish.o x86.o crypt_gensalt.o wrapper.o)

  $defs << "-D__SKIP_GNU"
  dir_config("bcrypt_ext")
  create_makefile("bcrypt_ext")
end
