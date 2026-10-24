require 'rails_helper'

RSpec.describe 'Help Center image URLs', type: :request do
  let(:account) { create(:account) }
  let(:author) { create(:user, account: account, role: :agent) }
  let(:portal) do
    create(:portal, account: account, custom_domain: 'support.example.test', config: { allowed_locales: ['en'], default_locale: 'en' })
  end
  let(:category) { create(:category, portal: portal, account: account, locale: 'en') }
  let(:blob) { get_blob_for(Rails.root.join('spec/assets/sample.png'), 'image/png') }
  let(:image_path) { Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true) }
  let(:image_src) { "#{image_path}?cw_image_width=320px" }
  let(:saved_image_url) { "http://localhost:3000#{image_src}" }
  let(:content) { "![article image](#{saved_image_url})\n\n`#{saved_image_url}`" }
  let!(:article) { create(:article, account: account, author: author, portal: portal, category: category, content: content) }
  let(:article_path) { "/hc/#{portal.slug}/articles/#{article.slug}" }
  let(:avatar_path) { URI.parse(author.avatar_url).request_uri }

  around do |example|
    with_modified_env(FRONTEND_URL: 'http://localhost:3000', HELPCENTER_URL: 'http://help.example.test') { example.run }
  end

  before do
    host! portal.custom_domain
    author.avatar.attach(fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png'))
  end

  it 'uses relative avatars in all three public avatar templates' do
    pages = {
      'classic' => ["/hc/#{portal.slug}/en", "/hc/#{portal.slug}/en/categories/#{category.slug}/articles"],
      'documentation' => [article_path]
    }
    pages.each do |layout, paths|
      portal.update!(config: portal.config.merge('layout' => layout))
      paths.each do |path|
        get path

        expect(response).to have_http_status(:success)
        expect(Nokogiri::HTML5(response.body).css('img').map { |image| image['src'] }).to include(avatar_path)
      end
    end
  end

  it 'keeps images relative after a custom domain changes without rewriting saved content' do
    %w[support.example.test docs.example.test].each do |domain|
      portal.update!(custom_domain: domain)
      host! domain
      get article_path

      expect(response).to have_http_status(:success)
      expect(Nokogiri::HTML5(response.body).at_css('img[alt="article image"]')['src']).to eq(image_src)
    end
    expect(article.reload.content).to eq(content)
  end

  it 'keeps images relative after the custom domain and optional Help Center host are removed' do
    original_avatar_url = author.avatar_url
    portal.update!(custom_domain: nil)
    { 'help.example.test' => 'http://help.example.test', 'localhost:3000' => '' }.each do |host, help_center_url|
      with_modified_env(HELPCENTER_URL: help_center_url) do
        host! host
        get article_path

        expect(response).to have_http_status(:success)
        expect(Nokogiri::HTML5(response.body).at_css('img[alt="article image"]')['src']).to eq(image_src)
      end
    end
    expect(article.reload.content).to eq(content)
    expect(author.reload.avatar_url).to eq(original_avatar_url)
  end

  it 'renders relative images in the plain dashboard preview' do
    host! 'localhost:3000'
    get article_path, params: { show_plain_layout: true }

    expect(response).to have_http_status(:success)
    expect(Nokogiri::HTML5(response.body).at_css('img[alt="article image"]')['src']).to eq(image_src)
  end

  it 'serves a valid signed image through the Help Center origin and the disk storage redirect' do
    get article_path
    rendered_src = Nokogiri::HTML5(response.body).at_css('img[alt="article image"]')['src']
    get rendered_src

    expect(response).to have_http_status(:redirect)
    expect(URI.parse(response.location).host).to eq(portal.custom_domain)
    follow_redirect!
    expect(response).to have_http_status(:success)
    expect(response.media_type).to eq('image/png')
    expect(response.body).to eq(blob.download)
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
