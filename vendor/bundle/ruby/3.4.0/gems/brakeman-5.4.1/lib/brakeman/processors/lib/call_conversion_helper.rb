module Brakeman
  module CallConversionHelper
    # Join two array literals into one.
    def join_arrays lhs, rhs, original_exp = nil
      if array? lhs and array? rhs
        result = Sexp.new(:array)
        result.line(lhs.line || rhs.line || 1)
        result.concat lhs[1..-1]
        result.concat rhs[1..-1]
        result
      else
        original_exp
      end
    end

    STRING_LENGTH_LIMIT = 50

    # Join two string literals into one.
    def join_strings lhs, rhs, original_exp = nil
      if string? lhs and string? rhs
        if (lhs.value.length + rhs.value.length > STRING_LENGTH_LIMIT)
          # Avoid gigantic strings
          lhs
        else
          result = Sexp.new(:str).line(lhs.line)
          result.value = lhs.value + rhs.value
          result
        end
      elsif call? lhs and lhs.method == :+ and string? lhs.first_arg and string? rhs
        joined = join_strings lhs.first_arg, rhs
        lhs.first_arg = joined
        lhs
      elsif safe_literal? lhs or safe_literal? rhs
        safe_literal(lhs.line)
      else
        original_exp
      end
    rescue Encoding::CompatibilityError => e
      # If the two strings are different encodings, we can't join them.
      Brakeman.debug e.inspect
      original_exp
    end

    def math_op op, lhs, rhs, original_exp = nil
      if number? lhs and number? rhs
        if op == :/ and rhs.value == 0 and not lhs.value.is_a? Float
          # Avoid division by zero
          return original_exp
        else
          value = lhs.value.send(op, rhs.value)
          Sexp.new(:lit, value).line(lhs.line)
        end
      elsif call? lhs and lhs.method == :+ and number? lhs.first_arg and number? rhs
        # (x + 1) + 2 -> (x + 3)
        lhs.first_arg = Sexp.new(:lit, lhs.first_arg.value + rhs.value).line(lhs.first_arg.line)
        lhs
      elsif safe_literal? lhs or safe_literal? rhs
        safe_literal(lhs.line)
      else
        original_exp
      end
    end

    # Process single integer access to an array.
    #
    # Returns the value inside the array, if possible.
    def process_array_access array, args, original_exp = nil
      if args.length == 1 and integer? args.first
        index = args.first.value

        #Have to do this because first element is :array and we have to skip it
        array[1..-1][index] or original_exp
      elsif all_literals? array
        safe_literal(array.line)
      else
        original_exp
      end
    end

    # Process hash access by returning the value associated
    # with the given argument.
    def process_hash_access hash, index, original_exp = nil
      if value = hash_access(hash, index)
        value # deep_clone?
      elsif all_literals? hash, :hash
        safe_literal(hash.line)
      else
        original_exp
      end
    end

    # You must check the return value for `nil`s -
    # which indicate a key could not be found.
    def hash_values_at hash, keys
      values = keys.map do |key|
        process_hash_access hash, key
      end

      Sexp.new(:array).concat(values).line(hash.line)
    end
  end
end
