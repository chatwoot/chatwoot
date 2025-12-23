# frozen_string_literal: true

require 'mkmf'

$CFLAGS << ' -std=c99'

create_makefile('commonmarker/commonmarker')
