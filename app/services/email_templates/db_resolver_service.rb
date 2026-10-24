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

  # The resolver instance is shared across threads, so per-lookup state is passed around instead of kept in ivars
  Lookup =Struct.new(:name, :prefix, :template_type, :locale, keyword_init: true)

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
    details = args.first if args.first.is_a?(Hash)
    lookup = Lookup.new(
      name: name,
      prefix: prefix,
      template_type: prefix.to_s.include?('layout') ? 'layout' : 'content',
      locale: Array(details&.dig(:locale)).first
    )
    db_template = find_db_template(lookup)

    return [] if db_template.blank?

    path = build_path(lookup)
    handler = ActionView::Template.registered_template_handler(:liquid)

    template_details = {
      locals: [],
      format: Mime['html'].to_sym,
      virtual_path: virtual_path(path, partial)
    }

    [ActionView::Template.new(db_template.body, "DB Template - #{db_template.id}", handler, **template_details)]
  end

  private

  def find_db_template(lookup)
    find_inbox_template(lookup) || find_account_template(lookup) || find_installation_template(lookup)
  end

  def find_inbox_template(lookup)
    return unless email_inbox_layout_lookup?(lookup) && branded_email_templates_enabled?

    find_template_for(@@model.where(inbox: Current.inbox), lookup)
  end

  def find_account_template(lookup)
    return unless Current.account
    return if account_layout_lookup?(lookup) && !branded_email_templates_enabled?

    find_template_for(@@model.where(account: Current.account, inbox: nil), lookup)
  end

  def find_installation_template(lookup)
    find_template_for(@@model.where(account: nil, inbox: nil), lookup)
  end

  def account_layout_lookup?(lookup)
    lookup.template_type == 'layout' && Current.account.present?
  end

  def email_inbox_layout_lookup?(lookup)
    account_layout_lookup?(lookup) && Current.inbox&.email?
  end

  def branded_email_templates_enabled?
    Current.account&.feature_enabled?(:branded_email_templates)
  end

  def find_template_for(relation, lookup)
    locale_candidates(lookup).each do |locale|
      template_names(lookup).each do |name|
        template = relation.find_by(name: name, template_type: lookup.template_type, locale: locale)
        return template if template.present?
      end
    end

    nil
  end

  def locale_candidates(lookup)
    EmailTemplate.locale_candidates(lookup.locale.presence || EmailTemplate::DEFAULT_LOCALE)
  end

  def template_names(lookup)
    [db_template_name(lookup), lookup.name].uniq
  end

  def db_template_name(lookup)
    return lookup.name if lookup.template_type == 'layout'

    build_path(lookup)
  end

  # Build path with eventual prefix
  def build_path(lookup)
    lookup.prefix.present? ? "#{lookup.prefix}/#{lookup.name}" : lookup.name
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
