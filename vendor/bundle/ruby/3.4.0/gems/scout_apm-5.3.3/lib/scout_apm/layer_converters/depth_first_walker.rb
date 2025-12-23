module ScoutApm
  module LayerConverters
    class DepthFirstWalker
      attr_reader :root_layer

      def initialize(root_layer)
        @root_layer = root_layer

        @on_blocks = []
        @before_blocks = []
        @after_blocks = []
      end

      def before(&block)
        @before_blocks << block
      end

      def after(&block)
        @after_blocks << block
      end

      def on(&block)
        @on_blocks << block
      end

      def walk(layer=root_layer)
        # Need to run this for the root layer the first time through.
        if layer == root_layer
          @before_blocks.each{|b| b.call(layer) }
          @on_blocks.each{|b| b.call(layer) }
        end

        layer.children.each do |child|
          @before_blocks.each{|b| b.call(child) }
          @on_blocks.each{|b| b.call(child) }
          walk(child)
          @after_blocks.each{|b| b.call(child) }
        end

        if layer == root_layer
          @after_blocks.each{|b| b.call(layer) }
        end

        nil
      end
    end
  end
end
