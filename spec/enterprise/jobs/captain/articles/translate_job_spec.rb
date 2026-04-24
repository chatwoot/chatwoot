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
    expect(translated).to have_attributes(
      title: 'Primeros pasos',
      content: '# Bienvenido\nEsta es una guía.',
      locale: 'es',
      category_id: category_es.id,
      author_id: user.id,
      status: 'draft',
      associated_article_id: article.id
    )
  end

  it 'creates a translated article without a category when target_category_id is nil' do
    expect do
      described_class.perform_now(account, article.id, 'es', nil, user)
    end.to change(Article, :count).by(1)

    translated = Article.last
    expect(translated).to have_attributes(
      title: 'Primeros pasos',
      locale: 'es',
      category_id: nil,
      status: 'draft',
      associated_article_id: article.id
    )
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

  context 'when a translation already exists' do
    let!(:existing_translation) do
      create(:article, portal: portal, category: category_es, account: account, author: user,
                       title: 'Old title', content: 'Old content', locale: 'es',
                       associated_article_id: article.id)
    end

    it 'updates the existing translation instead of creating a new one' do
      expect do
        described_class.perform_now(account, article.id, 'es', category_es.id, user)
      end.not_to change(Article, :count)

      existing_translation.reload
      expect(existing_translation).to have_attributes(
        title: 'Primeros pasos',
        content: '# Bienvenido\nEsta es una guía.',
        description: article.description
      )
    end
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
