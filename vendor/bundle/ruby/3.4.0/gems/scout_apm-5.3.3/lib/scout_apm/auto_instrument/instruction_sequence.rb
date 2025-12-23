
require 'scout_apm/auto_instrument/rails'

module ScoutApm
  module AutoInstrument
    module InstructionSequence
      def load_iseq(path)
        if Rails.controller_path?(path) & !Rails.ignore?(path)
          begin
            new_code = Rails.rewrite(path)
            return self.compile(new_code, path, path)
          rescue
            warn "Failed to apply auto-instrumentation to #{path}: #{$!}" if ENV['SCOUT_LOG_LEVEL'].to_s.downcase == "debug"
          end
        elsif Rails.ignore?(path)
          warn "AutoInstruments are ignored for path=#{path}." if ENV['SCOUT_LOG_LEVEL'].to_s.downcase == "debug"
        end

        return self.compile_file(path)
      end
    end

    # This should work (https://bugs.ruby-lang.org/issues/15572), but it doesn't.
    # RubyVM::InstructionSequence.extend(InstructionSequence)

    # So we do this instead:
    class << ::RubyVM::InstructionSequence
      prepend InstructionSequence
    end
  end
end
