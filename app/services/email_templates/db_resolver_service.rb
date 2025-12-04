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

  # Lightweight wrapper to adapt the new Hash result to an Object responding to .body and .id
  VirtualTemplate = Struct.new(:body, :id)

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

    # Determine type as Symbol: :layout or :content
    # .to_s is a safety check: if prefix is nil, nil.to_s becomes "" which prevents a crash
    # We use Symbols (:layout) because the DB uses Enums (0/1), and Rails maps Symbols to Integers automatically.
    @template_type = prefix.to_s.include?('layout') ? :layout : :content

    @db_template = find_db_template

    return [] if @db_template.blank?

    path = build_path(prefix)

    # ---------------------------------------------------------
    # DYNAMIC HANDLER DETECTION
    # ---------------------------------------------------------
    # Check if the content contains ERB tags (<%).
    # If yes, use ERB handler (allows Ruby code, yield, etc.)
    # If no, default to Liquid handler (Standard Chatwoot behavior)
    handler = if @db_template.body.include?('<%')
                ActionView::Template.registered_template_handler(:erb)
              else
                ActionView::Template.registered_template_handler(:liquid)
              end
    # ---------------------------------------------------------

    template_details = {
      locals: [],
      format: Mime['html'].to_sym,
      virtual_path: virtual_path(path, partial)
    }

    [ActionView::Template.new(@db_template.body, "DB Template - #{@db_template.id}", handler, **template_details)]
  end

  private

  def find_db_template
    # 1. Try New Advanced System (User -> Account -> Global)
    new_system_result = ::EmailTemplates::AdvancedTemplateResolver.new(
      user: Current.user,
      account: Current.account,
      template_name: @template_name,
      template_type: @template_type
    ).perform

    if new_system_result
      # Return a wrapper object that mimics the old ActiveRecord model interface (body, id)
      return VirtualTemplate.new(
        new_system_result[:html],
        "ADV-#{new_system_result[:template].id}"
      )
    end

    # 2. Fallback to Old System (Legacy EmailTemplate)
    find_account_template || find_installation_template
  end

  def find_account_template
    return unless Current.account

    # If @@model is nil (passed from ApplicationMailer), fallback to ::EmailTemplate class directly
    model = defined?(@@model) && @@model ? @@model : ::EmailTemplate
    model.find_by(name: @template_name, template_type: @template_type, account: Current.account)
  end

  def find_installation_template
    # If @@model is nil, fallback to ::EmailTemplate class directly
    model = defined?(@@model) && @@model ? @@model : ::EmailTemplate
    model.find_by(name: @template_name, template_type: @template_type, account: nil)
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
