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

export const resolveActionName = key =>
  macroActionTypes.find(i => i.key === key)?.label ?? key.toUpperCase();

export const getFileName = (id, actionType, files) => {
  if (!id || !files) return '';
  if (actionType === 'send_attachment') {
    const file = files.find(item => item.blob_id === id);
    if (file) return file.filename.toString();
  }
  return '';
};
