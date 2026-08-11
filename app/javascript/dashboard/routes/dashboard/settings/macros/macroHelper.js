import { MACRO_ACTION_TYPES as macroActionTypes } from 'dashboard/routes/dashboard/settings/macros/constants.js';
export const emptyMacro = {
  name: '',
  actions: [
    {
      action_name: 'assign_team',
      action_params: [],
    },
  ],
  visibility: 'global',
};

export const resolveActionName = key => {
  return macroActionTypes.find(i => i.key === key).label;
};

export const resolveTeamIds = (teams, ids) => {
  return ids
    .map(id => {
      if (id === 'nil') return 'None';
      const team = teams.find(i => i.id === id);
      return team ? team.name : '';
    })
    .join(', ');
};

export const resolveLabels = (labels, ids) => {
  return ids
    .map(id => {
      const label = labels.find(i => i.title === id);
      return label ? label.title : '';
    })
    .join(', ');
};

export const resolveAgents = (agents, ids) => {
  return ids
    .map(id => {
      if (id === 'nil') return 'None';
      if (id === 'self') return 'Self';
      const agent = agents.find(i => i.id === id);
      return agent ? agent.name : '';
    })
    .join(', ');
};

const resolveActionValue = (key, params, { labels, teams, agents }) => {
  const resolvers = {
    assign_team: () => resolveTeamIds(teams, params),
    add_label: () => resolveLabels(labels, params),
    remove_label: () => resolveLabels(labels, params),
    assign_agent: () => resolveAgents(agents, params),
    send_webhook_event: () => params[0],
    send_message: () => params[0],
    send_email_transcript: () => params[0],
    add_private_note: () => params[0],
  };

  return resolvers[key]?.() || '';
};

export const resolveMacroActions = (macro, records) =>
  macro.actions.map(({ action_name: name, action_params: params }) => ({
    actionName: resolveActionName(name),
    actionValue: resolveActionValue(name, params, records),
  }));

export const getFileName = (id, actionType, files) => {
  if (!id || !files) return '';
  if (actionType === 'send_attachment') {
    const file = files.find(item => item.blob_id === id);
    if (file) return file.filename.toString();
  }
  return '';
};
