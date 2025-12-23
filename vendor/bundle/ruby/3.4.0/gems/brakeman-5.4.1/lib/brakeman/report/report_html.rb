require 'cgi'
require 'brakeman/report/report_table.rb'

class Brakeman::Report::HTML < Brakeman::Report::Table
  HTML_CONFIDENCE = [ "<span class='high-confidence'>High</span>",
                      "<span class='med-confidence'>Medium</span>",
                      "<span class='weak-confidence'>Weak</span>" ]

  def initialize *args
    super

    @element_id = 0 #Used for HTML ids
  end

  def generate_report
    out = html_header <<
    generate_overview <<
    generate_warning_overview.to_s

    # Return early if only summarizing
    return out if tracker.options[:summary_only]

    out << generate_controllers.to_s if tracker.options[:report_routes] or tracker.options[:debug]
    out << generate_templates.to_s if tracker.options[:debug]
    out << generate_errors.to_s
    out << generate_warnings.to_s
    out << generate_controller_warnings.to_s
    out << generate_model_warnings.to_s
    out << generate_template_warnings.to_s
    out << generate_ignored_warnings.to_s
    out << "</body></html>"
  end

  def generate_overview
      locals = {
        :tracker => tracker,
        :warnings => all_warnings.length,
        :warnings_summary => warnings_summary,
        :number_of_templates => number_of_templates(@tracker),
        :ignored_warnings => ignored_warnings.length
        }

      Brakeman::Report::Renderer.new('overview', :locals => locals).render
  end

  #Generate listings of templates and their output
  def generate_templates
    out_processor = Brakeman::OutputProcessor.new
    template_rows = {}
    tracker.templates.each do |name, template|
      template.each_output do |out|
        out = CGI.escapeHTML(out_processor.format(out))
        template_rows[name] ||= []
        template_rows[name] << out.gsub("\n", ";").gsub(/\s+/, " ")
      end
    end

    template_rows = template_rows.sort_by{|name, value| name.to_s}

      Brakeman::Report::Renderer.new('template_overview', :locals => {:template_rows => template_rows}).render
  end

  def render_array template, headings, value_array, locals
    return if value_array.empty?

    Brakeman::Report::Renderer.new(template, :locals => locals).render
  end

  def convert_warning warning, original
    warning["Confidence"] = HTML_CONFIDENCE[original.confidence]
    warning["Message"] = with_context original, warning["Message"]
    warning["Warning Type"] = with_link original, warning["Warning Type"]
    warning
  end

  def with_link warning, message
    "<a rel=\"noreferrer\" href=\"#{warning.link}\">#{message}</a>"
  end

  def convert_template_warning warning, original
    warning = convert_warning warning, original
    warning["Called From"] = original.called_from
    warning["Template Name"] = original.template.name
    warning
  end

  def convert_ignored_warning warning, original
    warning = convert_warning(warning, original)
    warning['File'] = original.file.relative
    warning['Note'] = CGI.escapeHTML(@ignore_filter.note_for(original) || "")
    warning
  end

  #Return header for HTML output. Uses CSS from tracker.options[:html_style]
  def html_header
    if File.exist? tracker.options[:html_style]
      css = File.read tracker.options[:html_style]
    else
      raise "Cannot find CSS stylesheet for HTML: #{tracker.options[:html_style]}"
    end

    locals = {
      :css => css,
      :tracker => tracker,
      :checks => checks,
      :rails_version => rails_version,
      :brakeman_version => Brakeman::Version
      }

    Brakeman::Report::Renderer.new('header', :locals => locals).render
  end

  #Generate HTML for warnings, including context show/hidden via Javascript
  def with_context warning, message
    @element_id += 1
    context = context_for(warning)
    message = html_message(warning, message)

    code_id = "context#@element_id"
    message_id = "message#@element_id"
    full_message_id = "full_message#@element_id"
    alt = false
    output = "<div class='warning_message' onClick=\"toggle('#{code_id}');toggle('#{message_id}');toggle('#{full_message_id}')\" >" <<
    message <<
    "<table id='#{code_id}' class='context' style='display:none'>" <<
    "<caption>#{CGI.escapeHTML warning_file(warning) || ''}</caption>"

    output << <<-HTML
      <thead style='display:none'>
        <tr>
          <th>line number</th>
          <th>line content</th>
        </tr>
      </thead>
      <tbody>
    HTML

    unless context.empty?
      if warning.line - 1 == 1 or warning.line + 1 == 1
        error = " near_error"
      elsif 1 == warning.line
        error = " error"
      else
        error = ""
      end

      output << <<-HTML
        <tr class='context first#{error}'>
          <td class='context_line'>
            <pre class='context'>#{context.first[0]}</pre>
          </td>
          <td class='context'>
            <pre class='context'>#{CGI.escapeHTML context.first[1].chomp}</pre>
          </td>
        </tr>
      HTML

      if context.length > 1
        output << context[1..-1].map do |code|
          alt = !alt
          if code[0] == warning.line - 1 or code[0] == warning.line + 1
            error = " near_error"
          elsif code[0] == warning.line
            error = " error"
          else
            error = ""
          end

          <<-HTML
          <tr class='context#{alt ? ' alt' : ''}#{error}'>
            <td class='context_line'>
              <pre class='context'>#{code[0]}</pre>
            </td>
            <td class='context'>
              <pre class='context'>#{CGI.escapeHTML code[1].chomp}</pre>
            </td>
          </tr>
          HTML
        end.join
      end
    end

    output << "</tbody></table></div>"
  end

  #Escape warning message and highlight user input in HTML output
  def html_message warning, message
    message = message.to_html

    if warning.file
      if github_url = github_url(warning.file, warning.line)
        message << " <a href=\"#{github_url}\" target='_blank'>near line #{warning.line}</a>"
      elsif warning.line
        message << " near line #{warning.line}"
      end
    end

    if warning.code
      code = warning.format_with_user_input do |_, user_input|
        "[BMP_UI]#{user_input}[/BMP_UI]"
      end

      code = "<span class=\"code\">#{CGI.escapeHTML(code).gsub("[BMP_UI]", "<span class=\"user_input\">").gsub("[/BMP_UI]", "</span>")}</span>"
      full_message = "#{message}: #{code}"

      if warning.code.mass > 20
        message_id = "message#@element_id"
        full_message_id = "full_message#@element_id"

        "<span id='#{message_id}' style='display:block'>#{message}: ...</span>" <<
        "<span id='#{full_message_id}' style='display:none'>#{full_message}</span>"
      else
        full_message
      end
    else
      message
    end
  end
end
