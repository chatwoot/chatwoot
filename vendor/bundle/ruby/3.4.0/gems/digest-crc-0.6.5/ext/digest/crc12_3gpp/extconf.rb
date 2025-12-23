require 'mkmf'

have_header("stdint.h")
have_header('stddef.h')

create_header
create_makefile "crc12_3gpp_ext"
