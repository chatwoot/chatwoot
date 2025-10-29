export const buildFilterList = (items, type) =>
  // Build the filter list for the dropdown
  items.map(item => ({
    id: item.id,
    name: type === 'labels' ? item.title : item.name,
    type,
  }));

export const getActiveFilter = (filters, type, key) => {
  // Method is used to get the active filter from the filter list
  return filters.find(filterItem =>
    type === 'labels'
      ? filterItem.title === key
      : filterItem.id.toString() === key.toString()
  );
};

export const getFilterType = (input, direction) => {
  // Method is used to map the filter key to the filter type
  const filterMap = {
    keyToType: {
      assigned_agent_id: 'agents',
      inbox_id: 'inboxes',
      team_id: 'teams',
      sla_policy_id: 'sla',
      label_list: 'labels',
    },
    typeToKey: {
      agents: 'assigned_agent_id',
      inboxes: 'inbox_id',
      teams: 'team_id',
      sla: 'sla_policy_id',
      labels: 'label_list',
    },
  };
  return filterMap[direction][input];
};
