require 'mkmf'

have_header("stdint.h")
have_header('stddef.h')

create_header
create_makefile "crc16_zmodem_ext"
