require 'fileutils'

namespace :captain do
  namespace :tool_catalog do
    desc 'Validate the versioned Captain Tool Catalog evaluation dataset and toolsets without model calls'
    task validate_evaluation: :environment do
      model = ENV.fetch('MODEL', Llm::Config::DEFAULT_MODEL)
      summary = Captain::ToolCatalog::EvaluationRunner.new(model: model).validation_summary
      puts JSON.pretty_generate(summary)
    end

    desc 'Run the 15-tool versus 50-tool Captain Tool Catalog selection evaluation'
    task evaluate: :environment do
      model = ENV.fetch('MODEL', Llm::Config::DEFAULT_MODEL)
      output_path = Pathname.new(ENV.fetch('OUTPUT', Rails.root.join('tmp/captain-tool-catalog-eval.json').to_s))
      report = Captain::ToolCatalog::EvaluationRunner.new(model: model).perform

      FileUtils.mkdir_p(output_path.dirname)
      output_path.write(JSON.pretty_generate(report))
      puts JSON.pretty_generate(report.fetch('gate'))
      puts "Evaluation report: #{output_path}"
      abort('Captain Tool Catalog 50-tool gate failed') unless report.dig('gate', 'passed')
    end
  end
end
