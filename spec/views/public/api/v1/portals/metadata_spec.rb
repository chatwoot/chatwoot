require 'spec_helper'
require 'action_view'
require 'active_support/all'
require 'ostruct'
require 'nokogiri'
require 'commonmarker'
require_relative '../../../../../../lib/chatwoot_markdown_renderer'

RSpec.describe 'Public portal metadata' do
  let(:view_paths) { ActionView::PathSet.new([File.expand_path('../../../../../../app/views', __dir__)]) }
  let(:view) { ActionView::Base.with_empty_template_cache.new(ActionView::LookupContext.new(view_paths), {}, nil) }
  let(:portal) do
    Class.new do
      def display_title(locale)
        "Guide #{locale}"
      end
    end.new
  end
  let(:image_url) { 'https://example.com/article.png' }
  let(:article) { OpenStruct.new(title: 'Titre <localisé>', description: 'Résumé & détails', meta: {}) }
  let(:category) { OpenStruct.new(name: 'Catégorie <locale>', description: 'Description & détails') }
  let(:metadata) { Nokogiri::HTML.fragment(html).css('meta').to_h { |tag| [tag['property'] || tag['name'], tag['content']] } }

  describe 'articles' do
    let(:html) do
      view.render(partial: 'public/api/v1/portals/articles/meta_head',
                  locals: { article: article, portal: portal, locale: 'fr', og_image_url: image_url })
    end

    it 'uses the authored title and description when SEO overrides are absent' do
      expect(metadata).to include('title' => article.title, 'og:title' => article.title, 'twitter:title' => article.title,
                                  'description' => article.description, 'og:description' => article.description,
                                  'twitter:description' => article.description, 'og:type' => 'article', 'twitter:image' => image_url)
      expect(html).to include('<title>Titre &lt;localisé&gt; | Guide fr</title>', 'Résumé &amp; détails')
    end

    it 'preserves authored SEO overrides' do
      article.meta = { 'title' => 'SEO title', 'description' => 'SEO description' }
      expect(metadata).to include('og:title' => 'SEO title', 'twitter:title' => 'SEO title',
                                  'description' => 'SEO description', 'og:description' => 'SEO description',
                                  'twitter:description' => 'SEO description')
    end

    it 'uses a short plain-text excerpt when an authored description is absent' do
      article.description = nil
      article.content = "## Un titre\n\nUn **texte** avec un [lien](https://example.com). #{'Suite du texte. ' * 20}"
      expect(metadata['description']).to start_with('Un titre Un texte avec un lien.')
      expect(metadata['description'].length).to be <= 160
      expect(metadata['description']).not_to include('**', 'https://example.com')
    end

    it 'falls back when overrides are blank and omits absent descriptions' do
      article.meta = { 'title' => '', 'description' => '' }
      article.description = nil
      expect(metadata).to include('og:title' => article.title)
      expect(metadata).not_to have_key('description')
      expect(metadata).not_to have_key('og:description')
    end
  end

  describe 'categories' do
    let(:html) do
      view.render(partial: 'public/api/v1/portals/categories/meta_head',
                  locals: { category: category, portal: portal, locale: 'fr', og_image_url: image_url })
    end

    it 'publishes localized social titles, descriptions and images' do
      expect(metadata).to include('og:title' => 'Catégorie <locale> | Guide fr',
                                  'twitter:title' => 'Catégorie <locale> | Guide fr',
                                  'twitter:description' => category.description, 'twitter:image' => image_url, 'og:type' => 'website')
    end
  end
end
