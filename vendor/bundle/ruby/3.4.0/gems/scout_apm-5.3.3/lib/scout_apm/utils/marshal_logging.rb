module ScoutApm
  module Utils
    class Error < StandardError; end

    class InstanceVar
      attr_reader :name
      attr_reader :obj

      def initialize(name, obj, parent)
        @name = name
        @obj = obj
        @parent = parent
      end

      def to_s
        "#{@name} - #{obj.class}"
      end

      def history
        (@parent.nil? ? [] : @parent.history) + [to_s]
      end
    end

    class MarshalLogging
      def initialize(base_obj)
        @base_obj = base_obj
      end

      def dive
        to_investigate = [InstanceVar.new('Root', @base_obj, nil)]
        max_to_check = 10000
        checked = 0

        while (var = to_investigate.shift)
          checked += 1 
          if checked > max_to_check
            return "Limiting Checks (max = #{max_to_check})"
          end

          obj = var.obj

          if offending_hash?(obj)
            return "Found undumpable object: #{var.history}"
          end

          if !dumps?(obj)
            if obj.is_a? Hash
              keys = obj.keys
              keys.each do |key|
                to_investigate.push(
                  InstanceVar.new(key.to_s, obj[key], var)
                )
              end
            elsif obj.is_a? Array
              obj.each_with_index do |value, idx|
                to_investigate.push(
                  InstanceVar.new("Index #{idx}", value, var)
                )
              end
            else
              symbols = obj.instance_variables
              if !symbols.any?
                return "Found undumpable object: #{var.history}"
              end

              symbols.each do |sym|
                to_investigate.push(
                  InstanceVar.new(sym, obj.instance_variable_get(sym), var)
                )
              end
            end
          end
        end

        true
      end

      def dumps?(obj)
        Marshal.dump(obj)
        true
      rescue TypeError
        false
      end

      def offending_hash?(obj)
        obj.is_a?(Hash) && !obj.default_proc.nil?
      end
    end
  end
end
