# frozen_string_literal: true

module TestProf
  module Ext
    # Adds `ActiveRecord::Base#refind` method (through refinement)
    module ActiveRecordRefind
      refine ActiveRecord::Base do
        # Returns new reloaded record.
        #
        # Unlike `reload` this method returns
        # completely re-initialized instance.
        #
        # We need it to make sure that the state is clean.
        def refind
          self.class.find(send(self.class.primary_key))
        end
      end
    end
  end
end
