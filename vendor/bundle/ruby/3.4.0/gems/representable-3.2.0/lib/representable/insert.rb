module Representable
  class Pipeline < Array # i hate that.
    module Function
      class Insert
        def call(arr, func, options)
          arr = arr.dup
          delete!(arr, func) if options[:delete]
          replace!(arr, options[:replace], func) if options[:replace]
          arr
        end

      private
        def replace!(arr, old_func, new_func)
          arr.each_with_index { |func, index|
            if func.is_a?(Collect)
              arr[index] = Collect[*Pipeline::Insert.(func, new_func, replace: old_func)]
            end

            arr[index] = new_func if func==old_func
          }
        end

        def delete!(arr, removed_func)
          arr.delete(removed_func)

          # TODO: make nice.
          arr.each_with_index { |func, index|
            if func.is_a?(Collect)
              arr[index] = Collect[*Pipeline::Insert.(func, removed_func, delete: true)]
            end
          }
        end
      end
    end

    Insert = Pipeline::Function::Insert.new
  end # Pipeline
end
