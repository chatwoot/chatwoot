# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/language_support'
require 'new_relic/agent/vm/mri_vm'
require 'new_relic/agent/vm/jruby_vm'

module NewRelic
  module Agent
    module VM
      def self.snapshot
        vm.snapshot
      end

      def self.vm
        @vm ||= create_vm
      end

      def self.create_vm
        if NewRelic::LanguageSupport.jruby?
          JRubyVM.new
        else
          MriVM.new
        end
      end
    end
  end
end
