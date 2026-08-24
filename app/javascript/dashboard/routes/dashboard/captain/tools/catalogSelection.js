export const flattenTemplates = provider =>
  (provider?.categories || []).flatMap(category =>
    category.templates.map(template => ({
      ...template,
      category_key: category.key,
      category_name: category.name,
    }))
  );

export const selectedTemplates = (provider, selectedKeys) => {
  const selected = new Set(selectedKeys);
  return flattenTemplates(provider).filter(
    template => selected.has(template.key) && !template.installed
  );
};

export const buildSelections = (provider, selectedKeys, configurations) =>
  selectedTemplates(provider, selectedKeys).map(template => ({
    template_key: template.key,
    template_version: template.version,
    configuration: configurations[template.key] || {},
  }));

export const buildConnectionSelections = (provider, selectedKeys) =>
  selectedTemplates(provider, selectedKeys).map(template => ({
    template_key: template.key,
    template_version: template.version,
  }));

export const requiredScopes = templates =>
  [...new Set(templates.flatMap(template => template.required_scopes))].sort();

export const missingRequiredConfiguration = (templates, configurations) =>
  templates.some(template =>
    (template.configuration_schema.required || []).some(
      key => !String(configurations[template.key]?.[key] || '').trim()
    )
  );

export const updateSelections = provider =>
  flattenTemplates(provider)
    .filter(template => template.update_available)
    .map(template => ({
      template_key: template.key,
      template_version: template.version,
      configuration: template.installed_configuration || {},
    }));
