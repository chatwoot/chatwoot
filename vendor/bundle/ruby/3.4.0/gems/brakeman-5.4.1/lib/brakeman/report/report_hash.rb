# Generates a hash table for use in Brakeman tests
class Brakeman::Report::Hash < Brakeman::Report::Base
  def generate_report
    report = { :errors => tracker.errors,
               :controllers => tracker.controllers,
               :models => tracker.models,
               :templates => tracker.templates
              }

    [:generic_warnings, :controller_warnings, :model_warnings, :template_warnings].each do |meth|
      report[meth] = self.send(meth)
      report[meth].each do |w|
        w.message = w.format_message
        w.context = context_for(w).join("\n")
      end
    end

    report[:config] = tracker.config
    report[:checks_run] = tracker.checks.checks_run

    report
  end
end
