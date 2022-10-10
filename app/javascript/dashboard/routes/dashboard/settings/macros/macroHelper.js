import { MACRO_ACTION_TYPES as macroActionTypes } from './constants';

export const resolveActionName = key => {
  return macroActionTypes.find(i => i.key === key).label;
};

export const resolveTeamIds = (store, ids) => {
  const allTeams = store.getters['teams/getTeams'];
  return ids
    .map(id => {
      const team = allTeams.find(i => i.id === id);
      return team ? team.name : '';
    })
    .join(', ');
};

export const resolveLabels = (store, ids) => {
  const allLabels = store.getters['labels/getLabels'];
  return ids
    .map(id => {
      const label = allLabels.find(i => i.title === id);
      return label ? label.title : '';
    })
    .join(', ');
};

export const resolveSendEmailToTeam = obj => {
  return ` ${obj.message} - 
    ${resolveTeamIds(obj.team_ids)}`;
};

export const getDropdownValues = (type, store) => {
  switch (type) {
    case 'assign_team':
    case 'send_email_to_team':
      return store.getters['teams/getTeams'];
    case 'add_label':
      return store.getters['labels/getLabels'].map(i => {
        return {
          id: i.title,
          name: i.title,
        };
      });
    default:
      return [];
  }
};

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
