require 'brakeman/report/report_table'

class Brakeman::Report::Markdown < Brakeman::Report::Table

  class MarkdownTable < Terminal::Table

    def initialize options = {}, &block
      options[:style] ||= {}
      options[:style].merge!({
          :border_x => '-',
          :border_y => '|',
          :border_i => '|'
      })
      super options, &block
    end

    def render
      super.split("\n")[1...-1].join("\n")
    end
    alias :to_s :render

  end

  def initialize *args
    super
    @table = MarkdownTable
  end

  def generate_report
    out = "# BRAKEMAN REPORT\n\n" <<
    generate_metadata.to_s << "\n\n" <<
    generate_checks.to_s << "\n\n" <<
    "### SUMMARY\n\n" <<
    generate_overview.to_s << "\n\n" <<
    generate_warning_overview.to_s << "\n\n"

    #Return output early if only summarizing
    return out if tracker.options[:summary_only]

    if tracker.options[:report_routes] or tracker.options[:debug]
      out << "### CONTROLLERS"  << "\n\n" <<
      generate_controllers.to_s << "\n\n"
    end

    if tracker.options[:debug]
      out << "### TEMPLATES\n\n" <<
      generate_templates.to_s << "\n\n"
    end

    output_table("Errors", generate_errors, out)
    output_table("SECURITY WARNINGS", generate_warnings, out)
    output_table("Controller Warnings:", generate_controller_warnings, out)
    output_table("Model Warnings:", generate_model_warnings, out)
    output_table("View Warnings:", generate_template_warnings, out)

    out
  end

  def output_table title, result, output
    return unless result

    output << "### #{title}\n\n#{result.to_s}\n\n"
  end

  def generate_metadata
    MarkdownTable.new(
      :headings =>
        ['Application path', 'Rails version', 'Brakeman version', 'Started at', 'Duration']
    ) do |t|
      t.add_row([
        tracker.app_path,
        rails_version,
        Brakeman::Version,
        tracker.start_time,
        "#{tracker.duration} seconds",
      ])
    end
  end

  def generate_checks
    MarkdownTable.new(:headings => ['Checks performed']) do |t|
      t.add_row([checks.checks_run.sort.join(", ")])
    end
  end

  def convert_warning warning, original
    warning["Message"] = markdown_message original, warning["Message"]
    warning["Warning Type"] = "[#{warning['Warning Type']}](#{original.link})" if original.link
    warning
  end

  # Escape and code format warning message
  def markdown_message warning, message
    message = message.to_s

    if warning.file
      github_url = github_url warning.file, warning.line

      if github_url
        message << " near line [#{warning.line}](#{github_url})"
      elsif warning.line
        message << " near line #{warning.line}"
      end
    end

    if warning.code
      code = warning.format_code.gsub('`','``').gsub(/\A``|``\z/, '` `')
      message << ": `#{code}`"
    end

    message
  end
end
