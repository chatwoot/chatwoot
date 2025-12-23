# frozen_string_literal: true

require "json"

module TestProf
  module Utils
    # Generates static HTML reports with injected data
    module HTMLBuilder
      class << self
        def generate(data:, template:, output:)
          template = File.read(TestProf.asset_path(template))
          template.sub! "/**REPORT-DATA**/", data.to_json

          outpath = TestProf.artifact_path(output)
          File.write(outpath, template)
          outpath
        end
      end
    end
  end
end
