require 'rails_helper'

RSpec.describe PortalImageHelper do
  describe '#portal_image_src' do
    let(:image_path) { '/rails/active_storage/blobs/redirect/signed%2Bid/image.png?cw_image_width=320px&token=a%2Fb#preview' }

    around do |example|
      with_modified_env(FRONTEND_URL: 'https://app.example.test', HELPCENTER_URL: 'https://help.example.test') { example.run }
    end

    it 'preserves signed paths, queries and fragments for redirect and proxy URLs' do
      [image_path, image_path.sub('/redirect/', '/proxy/')].each do |path|
        expect(helper.portal_image_src("https://app.example.test#{path}")).to eq(path)
      end
    end

    it 'also accepts the configured Help Center origin' do
      expect(helper.portal_image_src("https://help.example.test#{image_path}")).to eq(image_path)
    end

    it 'compares host names case-insensitively and treats the default port as equivalent' do
      expect(helper.portal_image_src("https://APP.EXAMPLE.TEST:443#{image_path}")).to eq(image_path)
    end

    it 'allows a blank optional Help Center URL' do
      with_modified_env(HELPCENTER_URL: '') do
        expect(helper.portal_image_src("https://app.example.test#{image_path}")).to eq(image_path)
      end
    end

    it 'leaves external images unchanged when the optional Help Center URL has no scheme' do
      url = 'https://external.example.test/rails/active_storage/blobs/redirect/id/image.png'

      with_modified_env(HELPCENTER_URL: 'help.example.test') do
        expect(helper.portal_image_src(url)).to eq(url)
      end
    end

    [
      'https://external.example.test/rails/active_storage/blobs/redirect/id/image.png',
      'https://app.example.test.evil.test/rails/active_storage/blobs/redirect/id/image.png',
      'https://app.example.test:444/rails/active_storage/blobs/redirect/id/image.png',
      'http://app.example.test/rails/active_storage/blobs/redirect/id/image.png',
      'https://user@app.example.test/rails/active_storage/blobs/redirect/id/image.png',
      'https://bucket.example.test/image.png?signature=abc',
      'https://app.example.test/images/example.png',
      'https://app.example.test/rails/active_storage_other/image.png',
      '/rails/active_storage/blobs/redirect/id/image.png',
      '//app.example.test/rails/active_storage/blobs/redirect/id/image.png',
      'https://app.example.test/%invalid image'
    ].each do |url|
      it "leaves #{url} unchanged" do
        expect(helper.portal_image_src(url)).to eq(url)
      end
    end

    it 'uses the configured ActiveStorage route prefix' do
      allow(ActiveStorage).to receive(:routes_prefix).and_return('/files')

      expect(helper.portal_image_src('https://app.example.test/files/blobs/redirect/id/image.png')).to eq('/files/blobs/redirect/id/image.png')
      expect(helper.portal_image_src("https://app.example.test#{image_path}")).to eq("https://app.example.test#{image_path}")
    end
  end
end
