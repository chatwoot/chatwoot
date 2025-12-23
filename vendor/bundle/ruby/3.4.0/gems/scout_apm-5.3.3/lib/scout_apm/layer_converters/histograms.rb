module ScoutApm
  module LayerConverters
    class Histograms < ConverterBase
      # Updates immediate and long-term histograms for both job and web requests
      def record!
        if request.unique_name != :unknown
          context.request_histograms.add(request.unique_name, root_layer.total_call_time)
          context.request_histograms_by_time[@store.current_timestamp].
            add(request.unique_name, root_layer.total_call_time)
        end
        nil # not returning anything in the layer results ... not used
      end
    end
  end
end
