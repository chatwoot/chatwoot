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

  # the function has to accept(name, prefix, partial, _details, _locals = [])
  # _details contain local info which we can leverage in future
  # cause of codeclimate issue with 4 args, relying on (*args)
  def find_templates(name, prefix, partial, *_args)
    @template_name = name
    @template_type = prefix.include?('layout') ? 'layout' : 'content'
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
    find_account_template || find_installation_template
  end

  def find_account_template
    return unless Current.account

    @@model.find_by(name: @template_name, template_type: @template_type, account: Current.account)
  end

  def find_installation_template
    @@model.find_by(name: @template_name, template_type: @template_type, account: nil)
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
