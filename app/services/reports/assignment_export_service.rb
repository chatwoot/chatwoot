# frozen_string_literal: true

require 'csv'

class Reports::AssignmentExportService
  attr_reader :data

  def initialize(data)
    @data = data
  end

  def generate_csv
    CSV.generate(headers: true) do |csv|
      add_header(csv)
      add_summary_metrics(csv)
      add_inbox_metrics(csv)
      add_agent_metrics(csv)
    end
  end

  private

  def add_header(csv)
    csv << ['Assignment Metrics Report']
    csv << ['Generated at', Time.current]
    csv << []
  end

  def add_summary_metrics(csv)
    csv << ['Summary Metrics']
    csv << %w[Metric Value]
    data[:summary].each do |key, value|
      csv << [key.to_s.humanize, value]
    end
    csv << []
  end

  def add_inbox_metrics(csv)
    csv << ['Inbox Metrics']
    csv << ['Inbox Name', 'Total Assignments', 'Average Assignment Time', 'Unique Agents']
    data[:by_inbox].each do |inbox|
      csv << [inbox[:inbox_name], inbox[:total_assignments], inbox[:average_assignment_time], inbox[:unique_agents]]
    end
    csv << []
  end

  def add_agent_metrics(csv)
    csv << ['Agent Metrics']
    csv << ['Agent Name', 'Email', 'Assignment Count']
    data[:by_agent].each do |agent|
      csv << [agent[:agent_name], agent[:agent_email], agent[:assignment_count]]
    end
  end
end
