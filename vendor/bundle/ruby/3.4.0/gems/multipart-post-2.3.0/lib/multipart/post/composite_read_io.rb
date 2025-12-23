# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2006-2013, by Nick Sieger.
# Copyright, 2010, by Tohru Hashimoto.
# Copyright, 2011, by Jeff Hodges.
# Copyright, 2011, by Alex Koppel.
# Copyright, 2011, by Christine Yen.
# Copyright, 2011, by Gerrit Riessen.
# Copyright, 2011, by Luke Redpath.
# Copyright, 2013, by Mislav Marohnić.
# Copyright, 2013, by Leo Cassarani.
# Copyright, 2019, by Olle Jonsson.
# Copyright, 2019, by Patrick Davey.
# Copyright, 2021, by Lewis Cowles.
# Copyright, 2021-2022, by Samuel Williams.

module Multipart
  module Post
    # Concatenate together multiple IO objects into a single, composite IO object
    # for purposes of reading as a single stream.
    #
    # @example
    #     crio = CompositeReadIO.new(StringIO.new('one'),
    #                                StringIO.new('two'),
    #                                StringIO.new('three'))
    #     puts crio.read # => "onetwothree"
    class CompositeReadIO
      # Create a new composite-read IO from the arguments, all of which should
      # respond to #read in a manner consistent with IO.
      def initialize(*ios)
        @ios = ios.flatten
        @index = 0
      end

      # Read from IOs in order until `length` bytes have been received.
      def read(length = nil, outbuf = nil)
        got_result = false
        outbuf = outbuf ? outbuf.replace("") : String.new

        while io = current_io
          if result = io.read(length)
            got_result ||= !result.nil?
            result.force_encoding("BINARY") if result.respond_to?(:force_encoding)
            outbuf << result
            length -= result.length if length
            break if length == 0
          end
          advance_io
        end
        (!got_result && length) ? nil : outbuf
      end

      def rewind
        @ios.each { |io| io.rewind }
        @index = 0
      end

      private

      def current_io
        @ios[@index]
      end

      def advance_io
        @index += 1
      end
    end
  end
end

CompositeIO = Multipart::Post::CompositeReadIO
Object.deprecate_constant :CompositeIO
