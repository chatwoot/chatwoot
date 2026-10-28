class CustomExceptions::DataImport::FreshdeskTicketLimitError < CustomExceptions::Base
  MESSAGE = 'Freshdesk limits ticket listing to 300 pages. This import stopped after 30,000 tickets because the API cannot ' \
            'confirm that the ticket history is complete. A Freshdesk admin Account Export is required for any remaining history, ' \
            'but this importer does not support account exports yet.'.freeze

  def initialize
    super({})
  end

  def message
    MESSAGE
  end
end
