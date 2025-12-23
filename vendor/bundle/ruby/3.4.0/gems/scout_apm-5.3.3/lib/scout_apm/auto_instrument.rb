if RUBY_VERSION >= "2.3"
  require 'scout_apm/auto_instrument/instruction_sequence'
else
  warn "ScoutApm::AutoInstrument requires Ruby >= v2.3. Skipping."
end
