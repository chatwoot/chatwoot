Brakeman.load_brakeman_dependency 'terminal-table'

class Brakeman::Report::Table < Brakeman::Report::Base
  def initialize *args
    super
    @table = Terminal::Table
  end

  def generate_report
    summary_option = tracker.options[:summary_only]
    out = ""

    unless summary_option == :no_summary
      out << text_header <<
        "\n\n+SUMMARY+\n\n" <<
        truncate_table(generate_overview.to_s) << "\n\n" <<
        truncate_table(generate_warning_overview.to_s) << "\n"
    end

    #Return output early if only summarizing
    if summary_option == :summary_only or summary_option == true
      return out
    end

    if tracker.options[:report_routes] or tracker.options[:debug]
      out << "\n+CONTROLLERS+\n" <<
      truncate_table(generate_controllers.to_s) << "\n"
    end

    if tracker.options[:debug]
      out << "\n+TEMPLATES+\n\n" <<
      truncate_table(generate_templates.to_s) << "\n"
    end

    output_table("+Obsolete Ignore Entries+", generate_obsolete, out)
    output_table("+Errors+", generate_errors, out)
    output_table("+SECURITY WARNINGS+", generate_warnings, out)
    output_table("Controller Warnings:", generate_controller_warnings, out)
    output_table("Model Warnings:", generate_model_warnings, out)
    output_table("View Warnings:", generate_template_warnings, out)

    out << "\n"
    out
  end

  def output_table title, result, output
    return unless result

    output << "\n\n#{title}\n\n#{truncate_table(result.to_s)}"
  end

  def generate_overview
    num_warnings = all_warnings.length

    @table.new(:headings => ['Scanned/Reported', 'Total']) do |t|
      t.add_row ['Controllers', tracker.controllers.length]
      t.add_row ['Models', tracker.models.length - 1]
      t.add_row ['Templates', number_of_templates(@tracker)]
      t.add_row ['Errors', tracker.errors.length]
      t.add_row ['Security Warnings', "#{num_warnings} (#{warnings_summary[:high_confidence]})"]
      t.add_row ['Ignored Warnings', ignored_warnings.length] unless ignored_warnings.empty?
    end
  end

  #Generate table of how many warnings of each warning type were reported
  def generate_warning_overview
    types = warnings_summary.keys
    types.delete :high_confidence
    values = types.sort.collect{|warning_type| [warning_type, warnings_summary[warning_type]] }
    locals = {:types => types, :warnings_summary => warnings_summary}

    render_array('warning_overview', ['Warning Type', 'Total'], values, locals)
  end

  #Generate table of controllers and routes found for those controllers
  def generate_controllers
    controller_rows = controller_information

    cols = ['Name', 'Parent', 'Includes', 'Routes']

    locals = {:controller_rows => controller_rows}
    values = controller_rows.collect{|row| row.values_at(*cols) }
    render_array('controller_overview', cols, values, locals)
  end

  #Generate table of errors or return nil if no errors
  def generate_errors
    values = tracker.errors.collect{|error| [error[:error], error[:backtrace][0]]}
    render_array('error_overview', ['Error', 'Location'], values, {:tracker => tracker})
  end

  def generate_obsolete
    values = tracker.unused_fingerprints.collect{|fingerprint| [fingerprint] }
    render_array('obsolete_ignore_entries', ['fingerprint'], values, {:tracker => tracker})
  end

  def generate_warnings
    render_warnings generic_warnings,
                    :warning,
                    'security_warnings',
                    ["Confidence", "Class", "Method", "Warning Type", "CWE ID", "Message"],
                    'Class'
  end

  #Generate table of template warnings or return nil if no warnings
  def generate_template_warnings
    render_warnings template_warnings,
                    :template,
                    'view_warnings',
                    ['Confidence', 'Template', 'Warning Type', "CWE ID", 'Message'],
                    'Template'

  end

  #Generate table of model warnings or return nil if no warnings
  def generate_model_warnings
    render_warnings model_warnings,
                    :model,
                    'model_warnings',
                    ['Confidence', 'Model', 'Warning Type', "CWE ID", 'Message'],
                    'Model'
  end

  #Generate table of controller warnings or nil if no warnings
  def generate_controller_warnings
    render_warnings controller_warnings,
                    :controller,
                    'controller_warnings',
                    ['Confidence', 'Controller', 'Warning Type', "CWE ID", 'Message'],
                    'Controller'
  end

  def generate_ignored_warnings
    render_warnings ignored_warnings,
                    :ignored,
                    'ignored_warnings',
                    ['Confidence', 'Warning Type', "CWE ID", 'File', 'Message'],
                    'Warning Type'
  end

  def render_warnings warnings, type, template, cols, sort_col
    unless warnings.empty?
      rows = sort(convert_to_rows(warnings, type), sort_col)

      values = rows.collect { |row| row.values_at(*cols) }

      locals = { :warnings => rows }

      render_array(template, cols, values, locals)
    else
      nil
    end
  end

  #Generate listings of templates and their output
  def generate_templates
    out_processor = Brakeman::OutputProcessor.new
    template_rows = {}
    tracker.templates.each do |name, template|
      template.each_output do |out|
        out = out_processor.format out
        template_rows[name] ||= []
        template_rows[name] << out.gsub("\n", ";").gsub(/\s+/, " ")
      end
    end

    template_rows = template_rows.sort_by{|name, value| name.to_s}

    output = ''
    template_rows.each do |template|
      output << template.first.to_s << "\n\n"
      table = @table.new(:headings => ['Output']) do |t|
        # template[1] is an array of calls
        template[1].each do |v|
          t.add_row [v]
        end
      end

      output << table.to_s << "\n\n"
    end

    output
  end

  def convert_to_rows warnings, type = :warning
    warnings.map do |warning|
      w = warning.to_row type

      case type
      when :warning
        convert_warning w, warning
      when :ignored
        convert_ignored_warning w, warning
      when :template
        convert_template_warning w, warning
      else
        convert_warning w, warning
      end
    end
  end

  def convert_ignored_warning warning, original
    convert_warning warning, original
  end

  def convert_template_warning warning, original
    convert_warning warning, original
  end

  def sort rows, sort_col
    stabilizer = 0
    rows.sort_by do |row|
      stabilizer += 1

      row.values_at("Confidence", "Warning Type", sort_col) << stabilizer
    end
  end

  def render_array template, headings, value_array, locals
    return if value_array.empty?

    @table.new(:headings => headings) do |t|
      value_array.each { |value_row| t.add_row value_row }
    end
  end

  def convert_warning warning, original
    warning["Message"] = text_message original, warning["Message"]

    warning
  end

  #Escape warning message and highlight user input in text output
  def text_message warning, message
    message = message.to_s

    if warning.line
      message << " near line #{warning.line}"
    end

    if warning.code
      if @highlight_user_input and warning.user_input
        code = warning.format_with_user_input do |user_input, user_input_string|
          "+#{user_input_string}+"
        end
      else
        code = warning.format_code
      end

      message << ": #{code}"
    end

    message
  end

  #Generate header for text output
  def text_header
    <<-HEADER

+BRAKEMAN REPORT+

Application path: #{tracker.app_path}
Rails version: #{rails_version}
Brakeman version: #{Brakeman::Version}
Started at #{tracker.start_time}
Duration: #{tracker.duration} seconds
Checks run: #{checks.checks_run.sort.join(", ")}
HEADER
  end

  def truncate_table str
    @terminal_width ||= if @tracker.options[:table_width]
                          @tracker.options[:table_width]
                        elsif $stdin && $stdin.tty?
                          Brakeman.load_brakeman_dependency 'highline'
                          ::HighLine.default_instance.terminal.terminal_size[0]
                        else
                          80
                        end
    lines = str.lines

    lines.map do |line|
      if line.chomp.length > @terminal_width
        line[0..(@terminal_width - 3)] + ">>\n"
      else
        line
      end
    end.join
  end
end
