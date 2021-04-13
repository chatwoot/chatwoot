class LocalResource
  attr_reader :uri

  def initialize(uri, file_type = nil)
    @uri = URI(uri)
    @file_type = file_type
  end

  def file
    @file ||= Tempfile.new(tmp_filename, tmp_folder, encoding: encoding).tap do |f|
      io.rewind
      f.write(io.read)
      f.close
    end
    @file.open
  end

  def io
    # TODO: should we use RestClient here too ?
    @io ||= uri.open(read_timeout: 5)
  end

  def encoding
    io.rewind
    io.read.encoding
  end

  def find_file_type
    @file_type ? @file_type.split('/').last : Pathname.new(uri.path).extname
  end

  def tmp_filename
    [Time.now.to_i.to_s, find_file_type].join('.')
  end

  def tmp_folder
    Rails.root.join('tmp')
  end

  def filename
    File.basename(uri.path)
  end
end
