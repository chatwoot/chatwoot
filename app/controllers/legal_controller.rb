# frozen_string_literal: true

# Public legal pages for TikTok / Meta app review (no auth).
class LegalController < ActionController::Base # rubocop:disable Rails/ApplicationController
  layout 'legal'

  before_action :set_locale_and_doc

  def show
    @doc = InboxHub::LegalDocuments.fetch(@locale, @doc_id)
    @nav = InboxHub::LegalDocuments::NAV[@locale]
    @other_locale = @locale == 'en' ? 'es' : 'en'
  end

  private

  def set_locale_and_doc
    @locale = params[:locale].presence_in(InboxHub::LegalDocuments::LOCALES) || 'en'
    @doc_id = params[:doc].presence_in(InboxHub::LegalDocuments::DOCS)
    head :not_found and return if @doc_id.blank?
  end
end