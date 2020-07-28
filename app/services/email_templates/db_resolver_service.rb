# Code is heavily inspired by panaromic gem
# https://github.com/andreapavoni/panoramic
# We will try to find layouts and content from database
# layout will be rendered with erb and other content in html format
# Further proessing in liquid is implemented in mailers

class ::EmailTemplates::DbResolverService < ActionView::Resolver
  require 'singleton'
  include Singleton

  # Instantiate Resolver by passing a model.
  def self.using(model, options = {})
    class_variable_set(:@@model, model)
    class_variable_set(:@@resolver_options, options)
    instance
  end

  def find_templates(name, prefix, partial, _details, _locals = [])
    @template_name = name
    @template_type = prefix.include?('layout') ? 'layout' : 'content'
    @db_template = find_db_template

    return [] if @db_template.blank?

    path = build_path(prefix)
    handler = ActionView::Template.registered_template_handler(:liquid)

    template_details = {
      format: Mime['html'].to_sym,
      updated_at: @db_template.updated_at,
      virtual_path: virtual_path(path, partial)
    }

    [ActionView::Template.new(@db_template.body, "DB Template - #{@db_template.id}", handler, template_details)]
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
  # the function appends _to make the file nmae _file.ext if partial: true
  def virtual_path(path, partial)
    return path unless partial

    if (index = path.rindex('/'))
      path.insert(index + 1, '_')
    else
      "_#{path}"
    end
  end
end
