# Github Actions Formatter
# Formats warnings as workflow commands to create annotations in GitHub UI
class Brakeman::Report::Github < Brakeman::Report::Base
  def generate_report
    # @see https://docs.github.com/en/actions/reference/workflow-commands-for-github-actions#setting-a-warning-message
    errors.concat(warnings).join("\n")
  end

  def warnings
    all_warnings
      .map { |warning| "::warning file=#{warning_file(warning)},line=#{warning.line}::#{warning.message}" }
  end

  def errors
    tracker.errors.map do |error|
      if error[:exception].is_a?(Racc::ParseError)
        # app/services/balance.rb:4 :: parse error on value "..." (tDOT3)
        file, line = error[:exception].message.split(':').map(&:strip)[0,2]
        "::error file=#{file},line=#{line}::#{clean_message(error[:error])}"
      else
        "::error ::#{clean_message(error[:error])}"
      end
    end
  end

  private

  def clean_message(msg)
    msg.gsub('::','').squeeze(' ')
  end
end
