# frozen_string_literal: true

module Synapseos; end

# Renders a HTML form from a Pydantic v2 JSON Schema. Pure helper — no instance state,
# no Rails magic beyond standard tag helpers. Output is wired by PR5; this PR ships only
# the helper + specs.
# rubocop:disable Metrics/ModuleLength
module Synapseos::SchemaFormHelper
  TEXTAREA_LENGTH_THRESHOLD = 200
  PASSWORD_HINTS = %w[password secret token api_key apikey].freeze
  CREDENTIAL_REF_KEYS = %w[id name].freeze

  INPUT_CLASSES = 'mt-1 block w-full border border-slate-200 rounded-md p-2 text-sm'
  TEXTAREA_CLASSES = "#{INPUT_CLASSES} font-mono".freeze
  LABEL_CLASSES = 'block text-sm font-medium text-slate-700'
  HINT_CLASSES = 'mt-1 text-xs text-slate-500'
  ERROR_CLASSES = 'text-red-600 text-xs mt-1'
  FIELDSET_CLASSES = 'border border-slate-200 rounded-md p-4 mb-4'
  LEGEND_CLASSES = 'text-sm font-semibold text-slate-700'

  # Bundles the recursive descent state for a single property. Keeps signatures small.
  Field = Struct.new(:prop_name, :schema, :name, :path, :value, :required, :ctx, keyword_init: true) do
    def child(prop_name, prop_schema, value, required: false)
      Field.new(
        prop_name: prop_name,
        schema: prop_schema,
        name: "#{name}[#{prop_name}]",
        path: path.empty? ? prop_name.to_s : "#{path}.#{prop_name}",
        value: value,
        required: required,
        ctx: ctx
      )
    end
  end

  # Public entry. Renders a complete form body (no <form> wrapper) for the schema.
  # rubocop:disable Metrics/ParameterLists
  def synapseos_schema_form(schema:, values:, name_prefix: 'client', credentials: [], agents_meta: {}, errors: {})
    ctx = { schema: schema, credentials: credentials || [], agents_meta: agents_meta || {}, errors: errors || {} }
    root = Field.new(prop_name: nil, schema: schema, name: name_prefix, path: '', value: values || {}, required: false, ctx: ctx)
    safe_join([render_object(root), form_runtime_script])
  end
  # rubocop:enable Metrics/ParameterLists

  private

  def render_object(field)
    properties = (field.schema['properties'] || {})
    required = field.schema['required'] || []
    parts = properties.map do |prop_name, prop_schema|
      child_value = field.value.is_a?(Hash) ? field.value[prop_name] : nil
      render_property(field.child(prop_name, prop_schema, child_value, required: required.include?(prop_name)))
    end
    safe_join(parts)
  end

  def render_property(field)
    resolved = resolve_schema(field.schema, field.ctx[:schema])
    field.schema = resolved
    return render_credential_ref(field) if credential_ref?(resolved)
    return render_whatsapp_config(field) if whatsapp_config?(resolved)
    return render_dict_string(field) if dict_of_strings?(resolved)
    return render_agents_map(field) if agents_map?(resolved, field.ctx[:schema])
    return render_nested_object(field) if resolved['type'] == 'object'

    render_scalar(field)
  end

  # ---- scalars ----------------------------------------------------------------

  def render_scalar(field)
    field_wrapper(field_label(field), scalar_input(field), scalar_hint(field.schema), error_for(field.path, field.ctx))
  end

  def scalar_input(field)
    case scalar_kind(field)
    when :select   then select_input(field.name, field.schema['enum'], field.value)
    when :checkbox then checkbox_input(field.name, field.value)
    when :number   then number_input(field.name, field.schema, field.value)
    when :password then password_input(field.name, field.value)
    when :textarea then textarea_input(field.name, field.value)
    else text_input(field.name, field.value)
    end
  end

  def scalar_kind(field)
    schema = field.schema
    return :select if schema['enum'].is_a?(Array)
    return :checkbox if schema['type'] == 'boolean'
    return :number if %w[integer number].include?(schema['type'])
    return :password if password_field?(field.prop_name, schema)
    return :textarea if textarea?(schema)

    :text
  end

  def text_input(name, value)
    tag.input(type: 'text', name: name, value: value.to_s, class: INPUT_CLASSES)
  end

  def password_input(name, value)
    tag.input(type: 'password', name: name, value: value.to_s, class: INPUT_CLASSES)
  end

  def textarea_input(name, value)
    tag.textarea(value.to_s, name: name, rows: 4, class: TEXTAREA_CLASSES)
  end

  def number_input(name, schema, value)
    opts = { type: 'number', name: name, value: value.to_s, class: INPUT_CLASSES }
    opts[:min] = schema['minimum'] if schema.key?('minimum')
    opts[:max] = schema['maximum'] if schema.key?('maximum')
    tag.input(**opts)
  end

  def checkbox_input(name, value)
    bool = ActiveModel::Type::Boolean.new.cast(value)
    safe_join([
                tag.input(type: 'hidden', name: name, value: 'false'),
                tag.input(type: 'checkbox', name: name, value: 'true', checked: bool, class: 'h-4 w-4')
              ])
  end

  def select_input(name, enum, value)
    options = enum.map { |opt| tag.option(opt.to_s, value: opt.to_s, selected: value.to_s == opt.to_s) }
    tag.select(safe_join(options), name: name, class: INPUT_CLASSES)
  end

  # ---- $ref resolution + detection -------------------------------------------

  def resolve_schema(prop_schema, root)
    return prop_schema || {} unless prop_schema.is_a?(Hash)
    return resolve_ref(prop_schema['$ref'], root) if prop_schema['$ref']
    return resolve_any_of(prop_schema['anyOf'], root) if prop_schema['anyOf'].is_a?(Array)

    prop_schema
  end

  # anyOf with a single $ref + null → unwrap the $ref, treat as nullable.
  def resolve_any_of(any_of, root)
    non_null = any_of.reject { |s| s.is_a?(Hash) && s['type'] == 'null' }
    return resolve_schema(non_null.first, root) if non_null.length == 1

    {}
  end

  def resolve_ref(ref_path, root)
    return {} unless ref_path.is_a?(String) && ref_path.start_with?('#/')

    parts = ref_path.sub('#/', '').split('/')
    parts.inject(root) { |acc, key| acc.is_a?(Hash) ? acc[key] : nil } || {}
  end

  def credential_ref?(schema)
    return false unless schema.is_a?(Hash) && schema['type'] == 'object'

    props = schema['properties'] || {}
    CREDENTIAL_REF_KEYS.all? { |k| props.key?(k) } && props.size <= CREDENTIAL_REF_KEYS.size + 1
  end

  def whatsapp_config?(schema)
    return false unless schema.is_a?(Hash) && schema['type'] == 'object'

    provider = (schema['properties'] || {})['provider']
    return false unless provider.is_a?(Hash) && provider['enum'].is_a?(Array)

    provider['enum'].intersect?(%w[avisa waba hyperflow])
  end

  def dict_of_strings?(schema)
    return false unless schema.is_a?(Hash) && schema['type'] == 'object'

    ap = schema['additionalProperties']
    ap.is_a?(Hash) && ap['type'] == 'string'
  end

  def agents_map?(schema, root)
    return false unless schema.is_a?(Hash) && schema['type'] == 'object'

    ap = schema['additionalProperties']
    return false unless ap.is_a?(Hash) && ap['$ref'].is_a?(String)

    target = resolve_ref(ap['$ref'], root)
    target.is_a?(Hash) && target['properties'].is_a?(Hash) && target['properties'].key?('enabled')
  end

  # ---- composite renderers ---------------------------------------------------

  def render_nested_object(field)
    legend = tag.legend(humanize(field.prop_name), class: LEGEND_CLASSES)
    field.value = field.value.is_a?(Hash) ? field.value : {}
    tag.fieldset(safe_join([legend, render_object(field)]), class: FIELDSET_CLASSES)
  end

  def render_credential_ref(field)
    value = field.value.is_a?(Hash) ? field.value : {}
    label = tag.label(humanize(field.prop_name), class: LABEL_CLASSES)
    return render_credential_ref_fallback(field, value, label) if field.ctx[:credentials].empty?

    select = credential_select(field, value)
    hidden = tag.input(type: 'hidden', name: "#{field.name}[name]", value: value['name'].to_s, data: { credential_name: true })
    err = error_for("#{field.path}.id", field.ctx)
    tag.div(safe_join([label, select, hidden, err].compact), class: 'mb-4', data: { credential_ref: true })
  end

  def render_credential_ref_fallback(field, value, label)
    banner = tag.p('Credentials list unavailable — fill in IDs manually from your n8n instance.',
                   class: 'text-xs text-amber-700 bg-amber-50 border border-amber-200 rounded p-2 my-1')
    id_input = labeled_subfield('ID', text_input("#{field.name}[id]", value['id']), error_for("#{field.path}.id", field.ctx))
    name_input = labeled_subfield('Name', text_input("#{field.name}[name]", value['name']), error_for("#{field.path}.name", field.ctx))
    tag.div(safe_join([label, banner, id_input, name_input]), class: 'mb-4', data: { credential_ref: true })
  end

  def credential_select(field, value)
    creds = filter_credentials(field.ctx[:credentials], field.prop_name)
    options = creds.map do |c|
      cid = c[:id] || c['id']
      cname = c[:name] || c['name']
      tag.option(cname, value: cid, data: { name: cname }, selected: cid.to_s == value['id'].to_s)
    end
    tag.select(safe_join([tag.option('-- select --', value: '')] + options),
               name: "#{field.name}[id]", class: INPUT_CLASSES, data: { credential_select: true })
  end

  def filter_credentials(credentials, prop_name)
    type_hint = prop_name.to_s.downcase
    matched = credentials.select do |c|
      t = (c[:type] || c['type']).to_s.downcase
      t.present? && (t.include?(type_hint) || type_hint.include?(t))
    end
    matched.empty? ? credentials : matched
  end

  def render_whatsapp_config(field)
    field.value = field.value.is_a?(Hash) ? field.value : {}
    legend = tag.legend(humanize(field.prop_name), class: LEGEND_CLASSES)
    provider_field = whatsapp_provider_field(field)
    sub_blocks = (field.schema['properties'].keys - ['provider']).map { |key| whatsapp_sub_block(field, key) }
    tag.fieldset(safe_join([legend, provider_field, *sub_blocks]), class: FIELDSET_CLASSES, data: { whatsapp_config: true })
  end

  def whatsapp_provider_field(field)
    enum = field.schema['properties']['provider']['enum']
    field_wrapper(
      tag.label('Provider', class: LABEL_CLASSES),
      select_input("#{field.name}[provider]", enum, field.value['provider']),
      nil,
      error_for("#{field.path}.provider", field.ctx)
    )
  end

  def whatsapp_sub_block(field, key)
    sub_schema = resolve_schema(field.schema['properties'][key], field.ctx[:schema])
    sub_field = field.child(key, sub_schema, field.value[key] || {})
    tag.div(render_object(sub_field), class: 'mt-3', data: { provider_target: key })
  end

  def render_dict_string(field)
    parts = [
      tag.label(humanize(field.prop_name), class: LABEL_CLASSES),
      dict_rows_container(field),
      tag.button('+ Add', type: 'button', class: 'text-xs text-blue-600 mt-1', data: { dict_add: field.name }),
      error_for(field.path, field.ctx)
    ].compact
    tag.div(safe_join(parts), class: 'mb-4', data: { dict_editor: field.name })
  end

  def dict_rows_container(field)
    value = field.value.is_a?(Hash) ? field.value : {}
    rows = value.map { |k, v| dict_row(field.name, k.to_s, v.to_s) }
    rows << dict_row(field.name, '', '') if rows.empty?
    tag.div(safe_join(rows), data: { dict_rows: field.name })
  end

  def dict_row(full_name, key, val)
    key_input = tag.input(type: 'text', name: "#{full_name}[__keys__][]", value: key,
                          placeholder: 'key', class: "#{INPUT_CLASSES} flex-1", data: { dict_key: true })
    val_input = tag.input(type: 'text', name: "#{full_name}[__values__][]", value: val,
                          placeholder: 'value', class: "#{INPUT_CLASSES} flex-1", data: { dict_value: true })
    remove = tag.button('×', type: 'button', class: 'text-red-600 px-2', data: { dict_remove: true })
    tag.div(safe_join([key_input, val_input, remove]), class: 'flex gap-2 mb-1', data: { dict_row: true })
  end

  def render_agents_map(field)
    value = field.value.is_a?(Hash) ? field.value : {}
    target = resolve_ref(field.schema['additionalProperties']['$ref'], field.ctx[:schema])
    legend = tag.legend(humanize(field.prop_name), class: LEGEND_CLASSES)
    slugs = agent_slugs(field.ctx[:agents_meta], value)
    blocks = slugs.map { |slug| agent_block(field, target, slug, value) }
    tag.fieldset(safe_join([legend, *blocks]), class: FIELDSET_CLASSES, data: { agents_map: true })
  end

  # Available primeiro (template implementado), depois planned, depois orphan
  # values (slug em uso na config mas sem entry no agents_meta — caso raro).
  def agent_slugs(agents_meta, value)
    all = (agents_meta.keys.map(&:to_s) + value.keys.map(&:to_s)).uniq
    all.sort_by { |slug| [agent_status_rank(agents_meta, slug), slug] }
  end

  def agent_status_rank(agents_meta, slug)
    meta = agents_meta[slug] || agents_meta[slug.to_sym] || {}
    case (meta[:status] || meta['status']).to_s
    when 'available' then 0
    when 'planned'   then 1
    else 2
    end
  end

  def agent_block(field, target, slug, value)
    meta = field.ctx[:agents_meta][slug] || field.ctx[:agents_meta][slug.to_sym] || {}
    planned = (meta[:status] || meta['status']).to_s == 'planned'
    agent_value = value[slug] || value[slug.to_sym] || agent_default_values(target)
    body = planned ? planned_agent_body(meta) : agent_form_body(field, target, slug, agent_value)
    tag.details(safe_join([agent_summary(slug, meta, planned), tag.div(body, class: 'mt-3')]),
                class: agent_block_classes(planned),
                data: { agent_slug: slug, agent_status: planned ? 'planned' : 'available' })
  end

  def agent_form_body(field, target, slug, agent_value)
    sub_field = field.child(slug, target, agent_value)
    render_object(sub_field)
  end

  # Pra agentes planned, NÃO renderiza o form (evita o operador marcar
  # `enabled` e o deploy estourar). Mostra só descrição + dica de roadmap.
  def planned_agent_body(meta)
    desc = meta[:role_description] || meta['role_description']
    safe_join([
                tag.p('Workflows ainda não implementados — não pode ser ativado.',
                      class: 'text-xs font-medium text-amber-700 bg-amber-50 border border-amber-200 rounded p-2'),
                desc.present? ? tag.p(desc, class: 'text-xs text-slate-600 mt-2') : ''.html_safe
              ])
  end

  def agent_block_classes(planned)
    base = 'mb-2 border rounded-md p-3'
    planned ? "#{base} border-slate-200 bg-slate-50 opacity-75" : "#{base} border-slate-200"
  end

  def agent_summary(slug, meta, planned)
    display = meta[:display_name] || meta['display_name'] || slug.to_s
    role = meta[:role_tag] || meta['role_tag']
    chips = [
      role ? tag.span(role, class: 'ml-2 text-xs bg-slate-100 text-slate-700 rounded px-2 py-0.5') : nil,
      agent_status_chip(planned)
    ].compact
    tag.summary(safe_join([tag.strong(display), *chips]), class: 'cursor-pointer text-sm')
  end

  def agent_status_chip(planned)
    if planned
      tag.span('Em desenvolvimento',
               class: 'ml-2 text-xs bg-amber-100 text-amber-800 rounded px-2 py-0.5')
    else
      tag.span('Pronto',
               class: 'ml-2 text-xs bg-emerald-100 text-emerald-800 rounded px-2 py-0.5')
    end
  end

  def agent_default_values(target_schema)
    props = target_schema['properties'] || {}
    props.each_with_object({}) { |(k, v), acc| acc[k] = v['default'] if v.is_a?(Hash) && v.key?('default') }
  end

  # ---- presentation utils ----------------------------------------------------

  def field_wrapper(label, input, hint, err)
    parts = [label, input, hint, err].compact
    tag.div(safe_join(parts), class: 'mb-4')
  end

  def labeled_subfield(text, input, err)
    parts = [tag.label(text, class: 'text-xs text-slate-600 mt-2 block'), input, err].compact
    tag.div(safe_join(parts), class: 'mt-2')
  end

  def field_label(field)
    title = field.schema['title'] || humanize(field.prop_name)
    title = "#{title} *" if field.required
    tag.label(title, class: LABEL_CLASSES)
  end

  def scalar_hint(schema)
    parts = []
    parts << tag.span(schema['description']) if schema['description'].present?
    parts << tag.code(schema['pattern'], class: 'ml-1 text-xs bg-slate-100 px-1 rounded') if schema['pattern'].present?
    return nil if parts.empty?

    tag.p(safe_join(parts, ' '), class: HINT_CLASSES)
  end

  def textarea?(schema)
    desc = schema['description'].to_s.downcase
    return true if desc.include?('prompt')

    max = schema['maxLength']
    max.is_a?(Integer) && max > TEXTAREA_LENGTH_THRESHOLD
  end

  def password_field?(prop_name, schema)
    return true if schema['format'] == 'password'

    name = prop_name.to_s.downcase
    PASSWORD_HINTS.any? { |hint| name.include?(hint) }
  end

  def humanize(str)
    str.to_s.tr('_', ' ').split.map(&:capitalize).join(' ')
  end

  def error_for(path, ctx)
    msg = ctx[:errors][path] || ctx[:errors][path.to_sym]
    return nil if msg.blank?

    tag.p(msg, class: ERROR_CLASSES, data: { error_for: path })
  end

  # ---- inline runtime --------------------------------------------------------

  # rubocop:disable Metrics/MethodLength, Rails/OutputSafety
  def form_runtime_script
    js = <<~JS
      (function () {
        // Sync hidden name when a credential select changes.
        document.querySelectorAll('[data-credential-ref]').forEach(function (root) {
          var select = root.querySelector('[data-credential-select]');
          var hidden = root.querySelector('[data-credential-name]');
          if (!select || !hidden) return;
          select.addEventListener('change', function () {
            var opt = select.options[select.selectedIndex];
            hidden.value = opt ? (opt.dataset.name || '') : '';
          });
        });

        // Toggle whatsapp provider sub-blocks.
        document.querySelectorAll('[data-whatsapp-config]').forEach(function (root) {
          var providerSelect = root.querySelector('select[name$="[provider]"]');
          var blocks = root.querySelectorAll('[data-provider-target]');
          function refresh() {
            var current = providerSelect ? providerSelect.value : '';
            blocks.forEach(function (b) {
              b.style.display = b.dataset.providerTarget === current ? '' : 'none';
            });
          }
          if (providerSelect) providerSelect.addEventListener('change', refresh);
          refresh();
        });

        // Dict editor: add/remove rows.
        document.querySelectorAll('[data-dict-editor]').forEach(function (root) {
          var rows = root.querySelector('[data-dict-rows]');
          var addBtn = root.querySelector('[data-dict-add]');
          if (addBtn && rows) {
            addBtn.addEventListener('click', function () {
              var first = rows.querySelector('[data-dict-row]');
              if (!first) return;
              var clone = first.cloneNode(true);
              clone.querySelectorAll('input').forEach(function (i) { i.value = ''; });
              rows.appendChild(clone);
            });
          }
          root.addEventListener('click', function (e) {
            if (e.target && e.target.dataset && e.target.dataset.dictRemove !== undefined) {
              var row = e.target.closest('[data-dict-row]');
              if (row && rows.querySelectorAll('[data-dict-row]').length > 1) row.remove();
            }
          });
        });
      })();
    JS
    tag.script(js.html_safe, data: { synapseos_form_runtime: true })
  end
  # rubocop:enable Metrics/MethodLength, Rails/OutputSafety
end
# rubocop:enable Metrics/ModuleLength
