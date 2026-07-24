import { AUTOMATION_ACTION_TYPES } from 'dashboard/routes/dashboard/settings/automation/constants.js';

/** Actions that nest another flow/macro or need Flow file storage — not mid-flow. */
export const FLOW_EXCLUDED_ACTIONS = [
  'enter_flow',
  'execute_macro',
  'add_sla',
  'send_attachment',
];

/** Same catalog as Automations/Macros, minus mid-flow exclusions. */
export const FLOW_ACTION_TYPES = AUTOMATION_ACTION_TYPES.filter(
  ({ key }) => !FLOW_EXCLUDED_ACTIONS.includes(key)
);
