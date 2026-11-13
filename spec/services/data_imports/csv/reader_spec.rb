require 'rails_helper'

RSpec.describe DataImports::Csv::Reader do
  let(:contents) { "name,email\nJane,jane@example.com\n" }
  let(:blob) { ActiveStorage::Blob.create_and_upload!(io: StringIO.new(contents), filename: 'contacts.csv') }

  it 'rejects duplicate headers before yielding a row' do
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("email,email\none,two\n"), filename: 'contacts.csv')
    yielded = []
    expect do
      described_class.new(blob).each { |row| yielded << row }
    end.to raise_error(CustomExceptions::DataImport::InvalidCsvError, /unique/)
    expect(yielded).to be_empty
  end

  it 'accepts the maximum row count and rejects the next record' do
    stub_const('DataImports::Csv::UploadValidator::MAX_ROWS', 1)
    expect(described_class.new(blob).each.to_a.size).to eq(1)
    extra = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("#{contents}Second,second@example.com\n"), filename: 'contacts.csv')
    expect { described_class.new(extra).each.to_a }.to raise_error(CustomExceptions::DataImport::InvalidCsvError, /row limit/)
  end

  it 'rejects oversized unquoted fields' do
    stub_const('DataImports::Csv::UploadValidator::MAX_FIELD_SIZE', 10)
    expect { described_class.new(blob).each.to_a }.to raise_error(CSV::MalformedCSVError, /Field size exceeded/)
  end

  it 'accepts a field exactly at the limit' do
    stub_const('DataImports::Csv::UploadValidator::MAX_FIELD_SIZE', 'jane@example.com'.size)
    expect(described_class.new(blob).each.to_a.first.first['email']).to eq('jane@example.com')
  end

  it 'rejects header-only files' do
    header_only = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("name,email\n"), filename: 'contacts.csv')
    expect { described_class.new(header_only).each.to_a }.to raise_error(CustomExceptions::DataImport::InvalidCsvError, /at least one contact/)
  end

  context 'when an ordinary upload contains literal apostrophes and an errors column' do
    let(:contents) { "identifier,errors\n'+external-42,Previous rejection\n" }

    it 'preserves the identifier without assuming the apostrophe is an escape' do
      expect(described_class.new(blob).each.to_a.first.first['identifier']).to eq("'+external-42")
    end
  end

  context 'when a rejected CSV has an unsupported format version' do
    let(:contents) { "identifier,__chatwoot_csv_format\n'+external-42,unknown\n" }

    it 'rejects the row instead of guessing how to decode the identifier' do
      expect { described_class.new(blob).each.to_a }.to raise_error(
        CustomExceptions::DataImport::InvalidCsvError, 'Unsupported rejected contacts CSV format.'
      )
    end
  end
end
