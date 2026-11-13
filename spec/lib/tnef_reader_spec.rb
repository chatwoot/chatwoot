require 'rails_helper'

RSpec.describe TnefReader do
  let(:header) { [described_class::SIGNATURE, 1].pack('Vv') }
  let(:rend_data) { [2, described_class::ATT_ATTACH_RENDDATA, 14, "\0" * 14, 0].pack('CVVa*v') }
  let(:file_data) { [2, described_class::ATT_ATTACH_DATA, 3, 'abc', 'abc'.sum].pack('CVVa*v') }

  describe '.files' do
    it 'reads the names and contents of the attachments' do
      files = described_class.files(Rails.root.join('spec/fixtures/files/winmail.dat').binread)

      expect(files.map(&:name)).to eq(['avatar.png', 'quarterly-report.txt'])
      expect(files.last.data).to start_with('Q3 numbers')
    end

    it 'names an attachment that has no title' do
      expect(described_class.files(header + rend_data + file_data).map(&:name)).to eq(['attachment-1'])
    end

    it 'decodes the attachment title with the code page the stream declares' do
      body = [850, 0].pack('VV')
      codepage = [1, described_class::ATT_OEM_CODEPAGE, body.bytesize, body, body.sum].pack('CVVa*v')
      title = "r\x82sum\x82.pdf\0".b
      title_attribute = [2, described_class::ATT_ATTACH_TITLE, title.bytesize, title, title.sum].pack('CVVa*v')

      files = described_class.files(header + codepage + rend_data + title_attribute + file_data)

      expect(files.map(&:name)).to eq(['résumé.pdf'])
    end

    it 'ignores attachment data that has no attachment to belong to' do
      expect(described_class.files(header + file_data)).to be_empty
    end

    it 'raises when the stream holds too many attachment records' do
      records = rend_data * (described_class::MAX_ATTACHMENTS + 1)

      expect { described_class.files(header + records) }
        .to raise_error(described_class::Error, "more than #{described_class::MAX_ATTACHMENTS} attachments")
    end

    it 'raises when the data is not a TNEF stream' do
      expect { described_class.files('not a tnef file') }.to raise_error(described_class::Error, /not a TNEF stream/)
    end

    it 'raises when an attribute is longer than the stream' do
      huge_attribute = [2, described_class::ATT_ATTACH_DATA, 0xFFFFFFFF, 'abc'].pack('CVVa*')

      expect { described_class.files(header + rend_data + huge_attribute) }.to raise_error(described_class::Error, /longer than the stream/)
    end

    it 'raises when an attribute checksum does not match' do
      bad_checksum = [2, described_class::ATT_ATTACH_DATA, 3, 'abc', 0].pack('CVVa*v')

      expect { described_class.files(header + rend_data + bad_checksum) }.to raise_error(described_class::Error, /checksum/)
    end

    it 'raises when the stream is cut inside an attribute header' do
      expect { described_class.files(header + rend_data + [2, 3].pack('Cv')) }.to raise_error(described_class::Error, /header/)
    end

    it 'raises when the stream is cut inside an attribute' do
      expect { described_class.files(header + rend_data + file_data.byteslice(0, 10)) }.to raise_error(described_class::Error)
    end
  end
end
