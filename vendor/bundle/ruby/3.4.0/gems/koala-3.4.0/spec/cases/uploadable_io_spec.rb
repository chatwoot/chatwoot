# fake MIME::Types
module Koala::MIME
  module Types
    def self.type_for(type)
      # this should be faked out in tests
      nil
    end
  end
end

describe "Koala::HTTPService::UploadableIO" do
  def rails_3_mocks
    tempfile = double('Tempfile', :path => "foo")
    uploaded_file = double('ActionDispatch::Http::UploadedFile',
      :content_type => true,
      :tempfile => tempfile,
      :original_filename => "bar"
    )
    allow(tempfile).to receive(:respond_to?).with(:path).and_return(true)

    [tempfile, uploaded_file]
  end

  def sinatra_mocks
    {:type => "type", :tempfile => "Tempfile", :filename => "foo.bar"}
  end

  describe "the constructor" do
    describe "when given a file path" do
      before(:each) do
        @path = BEACH_BALL_PATH
        @koala_io_params = [@path]
      end

      describe "and a content type" do
        before :each do
          @stub_type = double("image/jpg")
          @koala_io_params.concat([@stub_type])
        end

        it "returns an UploadIO with the same file path" do
          expect(Koala::HTTPService::UploadableIO.new(*@koala_io_params).io_or_path).to eq(@path)
        end

        it "returns an UploadIO with the same content type" do
          expect(Koala::HTTPService::UploadableIO.new(*@koala_io_params).content_type).to eq(@stub_type)
        end

        it "returns an UploadIO with the file's name" do
          expect(Koala::HTTPService::UploadableIO.new(*@koala_io_params).filename).to eq(File.basename(@path))
        end
      end

      describe "and no content type" do
        it_should_behave_like "determining a mime type"
      end
    end

    describe "when given a File object" do
      before(:each) do
        @file = File.open(BEACH_BALL_PATH)
        @koala_io_params = [@file]
      end

      describe "and a content type" do
        before :each do
          @koala_io_params.concat(["image/jpg"])
        end

        it "returns an UploadIO with the same io" do
          expect(Koala::HTTPService::UploadableIO.new(*@koala_io_params).io_or_path).to eq(@koala_io_params[0])
        end

        it "returns an UploadableIO with the same content_type" do
          content_stub = @koala_io_params[1] = double('Content Type')
          expect(Koala::HTTPService::UploadableIO.new(*@koala_io_params).content_type).to eq(content_stub)
        end

        it "returns an UploadableIO with the right filename" do
          expect(Koala::HTTPService::UploadableIO.new(*@koala_io_params).filename).to eq(File.basename(@file.path))
        end
      end

      describe "and no content type" do
        it_should_behave_like "determining a mime type"
      end
    end


    describe "when given a Tempfile object" do
      before(:each) do
        @file = Tempfile.new('coucou')
        @koala_io_params = [@file]
      end

      describe "and a content type" do
        before :each do
          @koala_io_params.concat(["image/jpg"])
        end

        it "returns an UploadIO with the same io" do
          #Problem comparing Tempfile in Ruby 1.8, REE and Rubinius mode 1.8
          expect(Koala::HTTPService::UploadableIO.new(*@koala_io_params).io_or_path.path).to eq(@koala_io_params[0].path)
        end

        it "returns an UploadableIO with the same content_type" do
          content_stub = @koala_io_params[1] = double('Content Type')
          expect(Koala::HTTPService::UploadableIO.new(*@koala_io_params).content_type).to eq(content_stub)
        end

        it "returns an UploadableIO with the right filename" do
          expect(Koala::HTTPService::UploadableIO.new(*@koala_io_params).filename).to eq(File.basename(@file.path))
        end
      end

      describe "and no content type" do
        it_should_behave_like "determining a mime type"
      end
    end

    describe "when given an IO object" do
      before(:each) do
        @io = StringIO.open("abcdefgh")
        @koala_io_params = [@io]
      end

      describe "and a content type" do
        before :each do
          @koala_io_params.concat(["image/jpg"])
        end

        it "returns an UploadableIO with the same io" do
          expect(Koala::HTTPService::UploadableIO.new(*@koala_io_params).io_or_path).to eq(@koala_io_params[0])
        end

        it "returns an UploadableIO with the same content_type" do
          content_stub = @koala_io_params[1] = double('Content Type')
          expect(Koala::HTTPService::UploadableIO.new(*@koala_io_params).content_type).to eq(content_stub)
        end
      end

      describe "and no content type" do
        it "raises an exception" do
          expect { Koala::HTTPService::UploadableIO.new(*@koala_io_params) }.to raise_exception(Koala::KoalaError)
        end
      end
    end

    describe "when given a Rails 3 ActionDispatch::Http::UploadedFile" do
      before(:each) do
        @tempfile, @uploaded_file = rails_3_mocks
      end

      it "gets the path from the tempfile associated with the UploadedFile" do
        expected_path = double('Tempfile')
        expect(@tempfile).to receive(:path).and_return(expected_path)
        expect(Koala::HTTPService::UploadableIO.new(@uploaded_file).io_or_path).to eq(expected_path)
      end

      it "gets the content type via the content_type method" do
        expected_content_type = double('Content Type')
        expect(@uploaded_file).to receive(:content_type).and_return(expected_content_type)
        expect(Koala::HTTPService::UploadableIO.new(@uploaded_file).content_type).to eq(expected_content_type)
      end

      it "gets the filename from the UploadedFile" do
        expect(Koala::HTTPService::UploadableIO.new(@uploaded_file).filename).to eq(@uploaded_file.original_filename)
      end
    end

    describe "when given a Sinatra file parameter hash" do
      before(:each) do
        @file_hash = sinatra_mocks
      end

      it "gets the io_or_path from the :tempfile key" do
        expected_file = double('File')
        @file_hash[:tempfile] = expected_file

        uploadable = Koala::HTTPService::UploadableIO.new(@file_hash)
        expect(uploadable.io_or_path).to eq(expected_file)
      end

      it "gets the content type from the :type key" do
        expected_content_type = double('Content Type')
        @file_hash[:type] = expected_content_type

        uploadable = Koala::HTTPService::UploadableIO.new(@file_hash)
        expect(uploadable.content_type).to eq(expected_content_type)
      end

      it "gets the content type from the :type key" do
        uploadable = Koala::HTTPService::UploadableIO.new(@file_hash)
        expect(uploadable.filename).to eq(@file_hash[:filename])
      end
    end

    describe "for files with with recognizable MIME types" do
      # what that means is tested below
      it "should accept a file object alone" do
        params = [BEACH_BALL_PATH]
        expect { Koala::HTTPService::UploadableIO.new(*params) }.not_to raise_exception
      end

      it "should accept a file path alone" do
        params = [BEACH_BALL_PATH]
        expect { Koala::HTTPService::UploadableIO.new(*params) }.not_to raise_exception
      end
    end
  end

  describe "getting an UploadableIO" do
    before(:each) do
      @upload_io = double("UploadIO")
      allow(UploadIO).to receive(:new).with(anything, anything, anything).and_return(@upload_io)
    end

    context "if no filename was provided" do
      it "should call the constructor with the content type, file name, and a dummy file name" do
        expect(UploadIO).to receive(:new).with(BEACH_BALL_PATH, "content/type", anything).and_return(@upload_io)
        expect(Koala::HTTPService::UploadableIO.new(BEACH_BALL_PATH, "content/type").to_upload_io).to eq(@upload_io)
      end
    end

    context "if a filename was provided" do
      it "should call the constructor with the content type, file name, and the filename" do
        filename = "file"
        expect(UploadIO).to receive(:new).with(BEACH_BALL_PATH, "content/type", filename).and_return(@upload_io)
        Koala::HTTPService::UploadableIO.new(BEACH_BALL_PATH, "content/type", filename).to_upload_io
      end
    end
  end

  describe "getting a file" do
    it "returns the File if initialized with a file" do
      f = File.new(BEACH_BALL_PATH)
      expect(Koala::HTTPService::UploadableIO.new(f).to_file).to eq(f)
    end

    it "should open up and return a file corresponding to the path if io_or_path is a path" do
      result = double("File")
      expect(File).to receive(:open).with(BEACH_BALL_PATH).and_return(result)
      expect(Koala::HTTPService::UploadableIO.new(BEACH_BALL_PATH).to_file).to eq(result)
    end
  end

  describe ".binary_content?" do
    it "returns true for Rails 3 file uploads" do
      expect(Koala::HTTPService::UploadableIO.binary_content?(rails_3_mocks.last)).to be_truthy
    end

    it "returns true for Sinatra file uploads" do
      expect(Koala::HTTPService::UploadableIO.binary_content?(rails_3_mocks.last)).to be_truthy
    end

    it "returns true for File objects" do
      expect(Koala::HTTPService::UploadableIO.binary_content?(File.open(BEACH_BALL_PATH))).to be_truthy
    end

    it "returns false for everything else" do
      expect(Koala::HTTPService::UploadableIO.binary_content?(StringIO.new)).to be_falsey
      expect(Koala::HTTPService::UploadableIO.binary_content?(BEACH_BALL_PATH)).to be_falsey
      expect(Koala::HTTPService::UploadableIO.binary_content?(nil)).to be_falsey
    end
  end
end  # describe UploadableIO
