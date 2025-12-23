# frozen_string_literal: true
require 'delegate'

module Mail
  class PartsList < DelegateClass(Array)
    attr_reader :parts

    def initialize(*args)
      @parts = Array.new(*args)
      super @parts
    end

    # The #encode_with and #to_yaml methods are just implemented
    # for the sake of backward compatibility ; the delegator does
    # not correctly delegate these calls to the delegated object
    def encode_with(coder) # :nodoc:
      coder.represent_object(nil, @parts)
    end

    def to_yaml(options = {}) # :nodoc:
      @parts.to_yaml(options)
    end

    def attachments
      Mail::AttachmentsList.new(@parts)
    end

    def collect
      if block_given?
        ary = PartsList.new
        each { |o| ary << yield(o) }
        ary
      else
        to_a
      end
    end
    alias_method :map, :collect

    def map!
      raise NoMethodError, "#map! is not defined, please call #collect and create a new PartsList"
    end

    def collect!
      raise NoMethodError, "#collect! is not defined, please call #collect and create a new PartsList"
    end

    def inspect_structure(parent_id = '')
      enum_for(:map).with_index { |part, i|
        i = i + 1 # Use 1-based indexes since this is for humans to read
        id = parent_id.empty? ? "#{i}" : "#{parent_id}.#{i}"
        if part.content_type == "message/rfc822"
          sub_list = Mail.new(part.body).parts
        else
          sub_list = part.parts
        end
        id + '. ' + part.inspect +
          if sub_list.any?
            "\n" + sub_list.inspect_structure(id)
          end.to_s
      }.join("\n")
    end

    def recursive_each(&block)
      each do |part|
        if part.content_type == "message/rfc822"
          sub_list = Mail.new(part.body).parts
        else
          sub_list = part.parts
        end

        yield part

        sub_list.recursive_each(&block)
      end
    end

    def recursive_size
      i = 0
      recursive_each {|p| i += 1 }
      i
    end

    def recursive_delete_if
      delete_if { |part|
        if part.content_type == "message/rfc822"
          sub_list = Mail.new(part.body).parts
        else
          sub_list = part.parts
        end
        (yield part).tap {
          if sub_list.any?
            sub_list.recursive_delete_if {|part| yield part }
          end
        }
      }
    end

    def delete_attachments
      recursive_delete_if { |part|
        part.attachment?
      }
    end

    def sort
      self.class.new(@parts.sort)
    end

    def sort!(order)
      # stable sort should be used to maintain the relative order as the parts are added
      i = 0;
      sorted = @parts.sort_by do |a|
        # OK, 10000 is arbitrary... if anyone actually wants to explicitly sort 10000 parts of a
        # single email message... please show me a use case and I'll put more work into this method,
        # in the meantime, it works :)
        get_order_value(a, order) << (i += 1)
      end
      @parts.clear
      sorted.each { |p| @parts << p }
    end

  private

    def get_order_value(part, order)
      is_attachment = part.respond_to?(:attachment?) && part.attachment?
      has_content_type = part.respond_to?(:content_type) && !part[:content_type].nil?

      [is_attachment ? 1 : 0, (has_content_type ? order.index(part[:content_type].string.downcase) : nil) || 10000]
    end

  end
end
