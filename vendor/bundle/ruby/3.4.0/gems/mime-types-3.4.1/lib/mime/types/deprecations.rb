# frozen_string_literal: true

require "mime/types/logger"

# The namespace for MIME applications, tools, and libraries.
module MIME
  ##
  class Types
    # Used to mark a method as deprecated in the mime-types interface.
    def self.deprecated(klass, sym, message = nil, &block) # :nodoc:
      level =
        case klass
              when Class, Module
                "."
              else
                klass = klass.class
                "#"
        end
      message =
        case message
                when :private, :protected
                  "and will be #{message}"
                when nil
                  "and will be removed"
                else
                  message
        end
      MIME::Types.logger.warn <<-WARNING.chomp.strip
        #{caller(2..2).first}: #{klass}#{level}#{sym} is deprecated #{message}.
      WARNING

      return unless block
      block.call
    end
  end
end
