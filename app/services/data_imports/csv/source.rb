class DataImports::Csv::Source
  PROVIDER = 'csv'.freeze
  DISPLAY_NAME = 'CSV'.freeze

  def self.default_import_name
    'Contacts CSV import'
  end

  def self.source_metadata(_params)
    {}
  end

  def self.credential_name
    'source file'
  end

  def self.import_job_class
    DataImports::Csv::PreparationJob
  end

  def self.importer_class
    DataImports::Csv::Importer
  end

  def self.contacts_page_job_class
    DataImports::Csv::ContactsPageJob
  end

  def self.client_error?(_error)
    false
  end

  def initialize(data_import:)
    @data_import = data_import
  end
end
