####################################
#  Stubs for LayerConverter Tests  #
####################################
module ScoutApm
  module LayerConverters
    module Stubs
      def faux_walker(subscope_stubs = true)
        @w ||= stub

        if subscope_stubs && !@w_set_subscope_stubs
          @w_set_subscope_stubs = true
          @w.expects(:before)
          @w.expects(:after)
        end
        @w
      end

      def faux_request
        @req ||= stub(:root_layer => stub)
      end

      def faux_layer_finder
        @layer_finder ||= stub
        @layer_finder.stubs(:scope => stub)
        @layer_finder
      end

      def faux_store
        @store ||= stub
      end
    end
  end
end
