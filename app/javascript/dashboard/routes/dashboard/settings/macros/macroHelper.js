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
