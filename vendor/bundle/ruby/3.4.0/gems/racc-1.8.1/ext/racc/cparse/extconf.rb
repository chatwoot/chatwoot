# frozen_string_literal: true
#

require 'mkmf'
require_relative '../../../lib/racc/info'

$defs << "-D""RACC_INFO_VERSION=#{Racc::VERSION}"
create_makefile 'racc/cparse'
