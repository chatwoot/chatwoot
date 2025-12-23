require 'mkmf'

have_header("ruby/ruby.h") # Needed to check for Ruby <= 1.8.7
create_makefile('allocations')