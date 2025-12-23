require 'brakeman/report/report_table'

#Generated tab-separated output suitable for the Jenkins Brakeman Plugin:
#https://github.com/presidentbeef/brakeman-jenkins-plugin
class Brakeman::Report::Tabs < Brakeman::Report::Table
  def generate_report
    [[:generic_warnings, "General"], [:controller_warnings, "Controller"],
      [:model_warnings, "Model"], [:template_warnings, "Template"]].map do |meth, category|

      self.send(meth).map do |w|
        line = w.line || 0
        w.warning_type.gsub!(/[^\w\s]/, ' ')
        "#{(w.file.absolute)}\t#{line}\t#{w.warning_type}\t#{category}\t#{w.format_message}\t#{w.confidence_name}"
      end.join "\n"

    end.join "\n"

  end
end
