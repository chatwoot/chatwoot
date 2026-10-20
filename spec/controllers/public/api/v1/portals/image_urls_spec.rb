require 'rails_helper'

RSpec.describe 'Help Center image URLs', type: :request do
  let(:account) { create(:account) }
  let(:author) { create(:user, account: account, role: :agent) }
  let(:portal) do
    create(:portal, account: account, custom_domain: 'support.example.test', config: { allowed_locales: ['en'], default_locale: 'en' })
  end
  let(:category) { create(:category, portal: portal, account: account, locale: 'en') }
  let(:blob) do
    File.open(Rails.root.join('spec/assets/sample.png')) do |file|
      ActiveStorage::Blob.create_and_upload!(io: file, filename: 'article.png', content_type: 'image/png')
    end
  end
  let(:image_path) { Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true) }
  let(:saved_image_url) { "http://localhost:3000#{image_path}?cw_image_width=320px" }
  let(:content) { "![article image](#{saved_image_url})\n\n`#{saved_image_url}`" }
  let!(:article) { create(:article, account: account, author: author, portal: portal, category: category, content: content) }
  let(:article_path) { "/hc/#{portal.slug}/articles/#{article.slug}" }
  let(:avatar_path) { URI.parse(author.avatar_url).request_uri }
  let(:logo_path) { Rails.application.routes.url_helpers.rails_blob_path(portal.logo, only_path: true) }

  around do |example|
    with_modified_env(FRONTEND_URL: 'http://localhost:3000', HELPCENTER_URL: 'http://help.example.test') { example.run }
  end

  before do
    host! portal.custom_domain
    File.open(Rails.root.join('spec/assets/avatar.png')) do |file|
      author.avatar.attach(io: file, filename: 'avatar.png', content_type: 'image/png')
    end
    File.open(Rails.root.join('spec/assets/sample.png')) do |file|
      portal.logo.attach(io: file, filename: 'logo.png', content_type: 'image/png')
    end
  end

  %w[classic documentation].each do |layout|
    it "uses relative avatar, logo and favicon paths across #{layout} pages" do
      portal.update!(config: portal.config.merge('layout' => layout))
      paths = ["/hc/#{portal.slug}/en", "/hc/#{portal.slug}/en/categories/#{category.slug}",
               "/hc/#{portal.slug}/en/categories/#{category.slug}/articles", article_path]

      paths.each do |path|
        get path

        expect(response).to have_http_status(:success)
        document = Nokogiri::HTML5(response.body)
        image_sources = document.css('img').map { |image| image['src'] }
        expect(image_sources).to include(logo_path)
        expect(image_sources).to include(avatar_path) unless layout == 'classic' && path == article_path
        expect(document.at_css('link[rel="icon"]')['href']).to eq(logo_path)
      end
    end
  end

  it 'keeps images relative after a custom domain changes without rewriting saved content' do
    get article_path
    expect(response).to have_http_status(:success)
    expect(Nokogiri::HTML5(response.body).at_css('img[alt="article image"]')['src']).to eq("#{image_path}?cw_image_width=320px")

    portal.update!(custom_domain: 'docs.example.test')
    host! portal.custom_domain
    get article_path
    expect(response).to have_http_status(:success)
    expect(Nokogiri::HTML5(response.body).at_css('img[alt="article image"]')['src']).to eq("#{image_path}?cw_image_width=320px")

    expect(article.reload.content).to eq(content)
  end

  it 'keeps images relative after the custom domain and optional Help Center host are removed' do
    original_avatar_url = author.avatar_url
    portal.update!(custom_domain: nil)
    host! 'help.example.test'
    get article_path
    expect(response).to have_http_status(:success)
    expect(Nokogiri::HTML5(response.body).at_css('img[alt="article image"]')['src']).to eq("#{image_path}?cw_image_width=320px")

    with_modified_env(HELPCENTER_URL: '') do
      host! 'localhost:3000'
      get article_path
      expect(response).to have_http_status(:success)
      expect(Nokogiri::HTML5(response.body).at_css('img[alt="article image"]')['src']).to eq("#{image_path}?cw_image_width=320px")
    end
    expect(article.reload.content).to eq(content)
    expect(author.reload.avatar_url).to eq(original_avatar_url)
  end

  it 'renders relative images in the plain dashboard preview' do
    host! 'localhost:3000'
    get article_path, params: { show_plain_layout: true }

    expect(response).to have_http_status(:success)
    expect(Nokogiri::HTML5(response.body).at_css('img[alt="article image"]')['src']).to eq("#{image_path}?cw_image_width=320px")
  end

  it 'serves a valid signed image through the Help Center origin and the disk storage redirect' do
    get article_path
    image_src = Nokogiri::HTML5(response.body).at_css('img[alt="article image"]')['src']
    get image_src

    expect(response).to have_http_status(:redirect)
    expect(URI.parse(response.location).host).to eq(portal.custom_domain)
    follow_redirect!
    expect(response).to have_http_status(:success)
    expect(response.media_type).to eq('image/png')
    expect(response.body).to eq(blob.download)
  end

  it 'preserves a storage service signed URL when the relative blob route redirects' do
    service_url = 'https://bucket.example.test/article.png?signature=abc&expires=123'
    allow(blob.service).to receive(:url).and_return(service_url)

    get image_path

    expect(response).to redirect_to(service_url)
  end

  it 'also renders relative blob and avatar paths when ActiveStorage uses proxy routes' do
    allow(ActiveStorage).to receive(:resolve_model_to_route).and_return(:rails_storage_proxy)
    proxy_path = Rails.application.routes.url_helpers.rails_storage_proxy_path(blob, only_path: true)
    article.update!(content: "![article image](http://localhost:3000#{proxy_path})")
    portal.update!(config: portal.config.merge('layout' => 'documentation'))
    get article_path

    expect(response).to have_http_status(:success)
    document = Nokogiri::HTML5(response.body)
    expect(document.at_css('img[alt="article image"]')['src']).to start_with('/rails/active_storage/blobs/proxy/')
    expect(document.css('img').map { |image| image['src'] }).to include(a_string_starting_with('/rails/active_storage/representations/proxy/'))
  end

  it 'preserves saved Markdown and absolute avatar URLs in JSON and Markdown exports' do
    get "#{article_path}.json"

    expect(response).to have_http_status(:success)
    expect(response.parsed_body['content']).to eq(content)
    expect(response.parsed_body.dig('author', 'thumbnail')).to eq(author.avatar_url)

    get "#{article_path}.md"

    expect(response).to have_http_status(:success)
    expect(response.body).to eq(content)
    expect(article.reload.content).to eq(content)
  end
end
