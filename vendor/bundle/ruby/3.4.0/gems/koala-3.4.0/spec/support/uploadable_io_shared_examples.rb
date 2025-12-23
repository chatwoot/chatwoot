shared_examples_for "MIME::Types can't return results" do
  {
    "jpg" => "image/jpeg",
    "jpeg" => "image/jpeg",
    "png" => "image/png",
    "gif" => "image/gif"
  }.each_pair do |extension, mime_type|
    it "should properly get content types for #{extension} using basic analysis" do
      path = "filename.#{extension}"
      if @koala_io_params[0].is_a?(File)
        allow(@koala_io_params[0]).to receive(:path).and_return(path)
      else
        @koala_io_params[0] = path
      end
      expect(Koala::HTTPService::UploadableIO.new(*@koala_io_params).content_type).to eq(mime_type)
    end

    it "should get content types for #{extension} using basic analysis with file names with more than one dot" do
      path = "file.name.#{extension}"
      if @koala_io_params[0].is_a?(File)
        allow(@koala_io_params[0]).to receive(:path).and_return(path)
      else
        @koala_io_params[0] = path
      end
      expect(Koala::HTTPService::UploadableIO.new(*@koala_io_params).content_type).to eq(mime_type)
    end
  end

  describe "if the MIME type can't be determined" do
    before :each do
      path = "badfile.badextension"
      if @koala_io_params[0].is_a?(File)
        allow(@koala_io_params[0]).to receive(:path).and_return(path)
      else
        @koala_io_params[0] = path
      end
    end

    it "should throw an exception" do
      expect { Koala::HTTPService::UploadableIO.new(*@koala_io_params) }.to raise_exception(Koala::KoalaError)
    end
  end
end

shared_examples_for "determining a mime type" do
  describe "if MIME::Types is available" do
    it "should return an UploadIO with MIME::Types-determined type if the type exists" do
      type_result = ["type"]
      allow(Koala::MIME::Types).to receive(:type_for).and_return(type_result)
      expect(Koala::HTTPService::UploadableIO.new(*@koala_io_params).content_type).to eq(type_result.first)
    end
  end

  describe "if MIME::Types is unavailable" do
    before :each do
      # fake that MIME::Types doesn't exist
      allow(Koala::MIME::Types).to receive(:type_for).and_raise(NameError)
    end
    it_should_behave_like "MIME::Types can't return results"
  end

  describe "if MIME::Types can't find the result" do
    before :each do
      # fake that MIME::Types doesn't exist
      allow(Koala::MIME::Types).to receive(:type_for).and_return([])
    end

    it_should_behave_like "MIME::Types can't return results"
  end
end
