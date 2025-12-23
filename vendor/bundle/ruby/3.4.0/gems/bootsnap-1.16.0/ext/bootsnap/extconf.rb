# frozen_string_literal: true

require("mkmf")

if RUBY_ENGINE == "ruby"
  $CFLAGS << " -O3 "
  $CFLAGS << " -std=c99"

  # ruby.h has some -Wpedantic fails in some cases
  # (e.g. https://github.com/Shopify/bootsnap/issues/15)
  unless ["0", "", nil].include?(ENV["BOOTSNAP_PEDANTIC"])
    $CFLAGS << " -Wall"
    $CFLAGS << " -Werror"
    $CFLAGS << " -Wextra"
    $CFLAGS << " -Wpedantic"

    $CFLAGS << " -Wno-unused-parameter" # VALUE self has to be there but we don't care what it is.
    $CFLAGS << " -Wno-keyword-macro" # hiding return
    $CFLAGS << " -Wno-gcc-compat" # ruby.h 2.6.0 on macos 10.14, dunno
    $CFLAGS << " -Wno-compound-token-split-by-macro"
  end

  create_makefile("bootsnap/bootsnap")
else
  File.write("Makefile", dummy_makefile($srcdir).join)
end
