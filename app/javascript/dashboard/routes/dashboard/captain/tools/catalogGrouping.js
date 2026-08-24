const titleize = value =>
  value
    .split('_')
    .map(word => `${word.charAt(0).toUpperCase()}${word.slice(1)}`)
    .join(' ');

const customToolHost = tool => {
  try {
    return new URL(tool.endpoint_url).hostname;
  } catch {
    return '';
  }
};

export const groupCatalogTools = (tools, providers) => {
  const providersByKey = Object.fromEntries(
    providers.map(provider => [provider.key, provider])
  );

  return Object.values(
    tools
      .filter(tool => tool.source_kind === 'catalog')
      .reduce((groups, tool) => {
        const provider = providersByKey[tool.provider_key] || {};
        const group = groups[tool.provider_key] || {
          key: tool.provider_key,
          name: provider.name || titleize(tool.provider_key),
          connection: provider.connection || null,
          categories: {},
          updateCount: provider.update_count || 0,
          toolCount: 0,
        };
        const category = group.categories[tool.category_key] || {
          key: tool.category_key,
          name: titleize(tool.category_key),
          tools: [],
        };

        category.tools.push(tool);
        group.categories[tool.category_key] = category;
        group.toolCount += 1;
        if (tool.connection_required) group.connectionRequired = true;
        groups[tool.provider_key] = group;
        return groups;
      }, {})
  ).map(group => ({
    ...group,
    categories: Object.values(group.categories),
  }));
};

export const groupCustomTools = tools =>
  Object.values(
    tools
      .filter(tool => tool.source_kind !== 'catalog')
      .reduce((groups, tool) => {
        const host = customToolHost(tool);
        const key = host || 'custom';
        const group = groups[key] || {
          key,
          name: host || 'Custom tools',
          tools: [],
        };
        group.tools.push(tool);
        groups[key] = group;
        return groups;
      }, {})
  );
