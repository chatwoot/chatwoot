require 'rails_helper'

RSpec.describe Captain::Articles::TranslateJob, type: :job do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let!(:portal) { create(:portal, account: account, config: { allowed_locales: %w[en es] }) }
  let!(:category_en) { create(:category, portal: portal, account: account, locale: 'en', slug: 'getting-started') }
  let!(:category_es) { create(:category, portal: portal, account: account, locale: 'es', slug: 'primeros-pasos') }
  let!(:article) do
    create(:article, portal: portal, category: category_en, account: account, author: user,
                     title: 'Getting Started', content: '# Welcome\nThis is a guide.')
  end

  let(:translation_service) { instance_double(Captain::Llm::ArticleTranslationService) }

  before do
    allow(Captain::Llm::ArticleTranslationService).to receive(:new).and_return(translation_service)
    allow(translation_service).to receive(:translate_title).and_return('Primeros pasos')
    allow(translation_service).to receive(:translate_content).and_return('# Bienvenido\nEsta es una guía.')
  end

  it 'queues on the low queue' do
    expect { described_class.perform_later(account, article.id, 'es', category_es.id, user) }
      .to have_enqueued_job.on_queue('low')
  end

  it 'creates a translated article as draft' do
    expect do
      described_class.perform_now(account, article.id, 'es', category_es.id, user)
    end.to change(Article, :count).by(1)

    translated = Article.last
    expect(translated.title).to eq('Primeros pasos')
    expect(translated.content).to eq('# Bienvenido\nEsta es una guía.')
    expect(translated.locale).to eq('es')
    expect(translated.category_id).to eq(category_es.id)
    expect(translated.author_id).to eq(user.id)
    expect(translated.status).to eq('draft')
  end

  it 'links translated article to the source via associated_article_id' do
    described_class.perform_now(account, article.id, 'es', category_es.id, user)

    translated = Article.last
    expect(translated.associated_article_id).to eq(article.id)
  end

  it 'calls the translation service with the correct language' do
    described_class.perform_now(account, article.id, 'es', category_es.id, user)

    expect(translation_service).to have_received(:translate_title).with('Getting Started', target_language: 'Spanish')
    expect(translation_service).to have_received(:translate_content).with('# Welcome\nThis is a guide.', target_language: 'Spanish')
  end

  it 'uses language_map for locale name resolution' do
    described_class.perform_now(account, article.id, 'pt_BR', category_es.id, user)

    expect(translation_service).to have_received(:translate_title).with(anything, target_language: 'Portuguese (Brazil)')
  end

  context 'when translation service fails' do
    before do
      allow(translation_service).to receive(:translate_title).and_raise(StandardError, 'LLM timeout')
    end

    it 'raises the error and does not create an article' do
      expect do
        described_class.perform_now(account, article.id, 'es', category_es.id, user)
      end.to raise_error(StandardError, 'LLM timeout').and not_change(Article, :count)
    end
  end
end
