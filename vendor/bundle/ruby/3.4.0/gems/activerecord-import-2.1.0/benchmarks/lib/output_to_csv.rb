# frozen_string_literal: true

require 'csv'

module OutputToCSV
  def self.output_results( filename, results )
    CSV.open( filename, 'w' ) do |csv|
      # Iterate over each result set, which contains many results
      results.each do |result_set|
        columns = []
        times = []
        result_set.each do |result|
          columns << result.description
          times << result.tms.real
        end
        csv << columns
        csv << times
      end
    end
  end
end
