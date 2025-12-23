# frozen_string_literal: true

require_relative "assertions/dom_assertions"
require_relative "assertions/selector_assertions"

module Rails
  module Dom
    module Testing
      module Assertions
        include DomAssertions
        include SelectorAssertions
      end
    end
  end
end
