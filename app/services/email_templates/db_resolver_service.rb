# Code is heavily inspired by panaromic gem
# https://github.com/andreapavoni/panoramic
# We will try to find layouts and content from database
# layout will be rendered with erb and other content in html format
# Further processing in liquid is implemented in mailers

# NOTE: rails resolver looks for templates in cache first
# which we don't want to happen here
# so we are overriding find_all method in action view resolver
# If anything breaks - look into rails : actionview/lib/action_view/template/resolver.rb

class ::EmailTemplates::DbResolverService < ActionView::Resolver
  require 'singleton'
  include Singleton

  # Instantiate Resolver by passing a model.
  def self.using(model, options = {})
    class_variable_set(:@@model, model)
    class_variable_set(:@@resolver_options, options)
    instance
  end

  # Since rails picks up files from cache. lets override the method
  # Normalizes the arguments and passes it on to find_templates.
  # rubocop:disable Metrics/ParameterLists
  def find_all(name, prefix = nil, partial = false, details = {}, key = nil, locals = [])
    locals = locals.map(&:to_s).sort!.freeze
    _find_all(name, prefix, partial, details, key, locals)
  end
  # rubocop:enable Metrics/ParameterLists

  # the function has to accept(name, prefix, partial, details, locals = [])
  # details contain local info which we can leverage in future
  # cause of codeclimate issue with 4 args, relying on (*args)
  def find_templates(name, prefix, partial, *args)
    @template_name = name
    @template_type = prefix.to_s.include?('layout') ? 'layout' : 'content'
    @prefix = prefix
    @details = args.first if args.first.is_a?(Hash)
    @db_template = find_db_template

    return [] if @db_template.blank?

    path = build_path(prefix)
    handler = ActionView::Template.registered_template_handler(:liquid)

    template_details = {
      locals: [],
      format: Mime['html'].to_sym,
      virtual_path: virtual_path(path, partial)
    }

    [ActionView::Template.new(@db_template.body, "DB Template - #{@db_template.id}", handler, **template_details)]
  end

  private

  def find_db_template
    find_inbox_template || find_account_template || find_installation_template
  end

  def find_inbox_template
    return unless email_inbox_layout_lookup? && branded_email_templates_enabled?

    find_template_for(@@model.where(inbox: Current.inbox))
  end

  def find_account_template
    return unless Current.account
    return if account_layout_lookup? && !branded_email_templates_enabled?

    find_template_for(@@model.where(account: Current.account, inbox: nil))
  end

  def find_installation_template
    find_template_for(@@model.where(account: nil, inbox: nil))
  end

  def account_layout_lookup?
    @template_type == 'layout' && Current.account.present?
  end

  def email_inbox_layout_lookup?
    account_layout_lookup? && Current.inbox&.email?
  end

  def branded_email_templates_enabled?
    Current.account&.feature_enabled?(:branded_email_templates)
  end

  def find_template_for(relation)
    locale_candidates.each do |locale|
      template_names.each do |name|
        template = relation.find_by(name: name, template_type: @template_type, locale: locale)
        return template if template.present?
      end
    end

    nil
  end

  def locale_candidates
    locale = Array(@details&.dig(:locale)).first
    EmailTemplate.locale_candidates(locale.presence || EmailTemplate::DEFAULT_LOCALE)
  end

  def template_names
    [db_template_name, @template_name].uniq
  end

  def db_template_name
    return @template_name if @template_type == 'layout'

    build_path(@prefix)
  end

  # Build path with eventual prefix
  def build_path(prefix)
    prefix.present? ? "#{prefix}/#{@template_name}" : @template_name
  end

  # returns a path depending if its a partial or template
  # params path: path/to/file.ext  partial: true/false
  # the function appends _to make the file name _file.ext if partial: true
  def virtual_path(path, partial)
    return path unless partial

    if (index = path.rindex('/'))
      path.insert(index + 1, '_')
    else
      "_#{path}"
    end
  end
end
