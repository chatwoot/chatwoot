class Workflow::Template
  attr_accessor :params

  def initialize(params)
    @params = params
  end

  def id
    params[:id]
  end

  def name
    params[:name]
  end

  def description
    params[:description]
  end

  def config
    params[:config]
  end

  def account_templates
    Current.account.workflow_account_templates.where(template_id: id)
  end

  class << self
    def workflow_templates
      Hashie::Mash.new(WORKFLOW_TEMPLATES_CONFIG)
    end

    def all
      workflow_templates.values.each_with_object([]) do |workflow_template, result|
        result << new(workflow_template)
      end
    end

    def find(params)
      all.detect { |workflow_template| workflow_template.id == params[:id] }
    end
  end
end
