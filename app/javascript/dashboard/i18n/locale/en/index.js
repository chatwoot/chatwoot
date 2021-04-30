import { default as _agentMgmt } from './agentMgmt.json';
import { default as _labelsMgmt } from './labelsMgmt.json';
import { default as _cannedMgmt } from './cannedMgmt.json';
import { default as _chatlist } from './chatlist.json';
import { default as _contact } from './contact.json';
import { default as _conversation } from './conversation.json';
import { default as _inboxMgmt } from './inboxMgmt.json';
import { default as _login } from './login.json';
import { default as _report } from './report.json';
import { default as _resetPassword } from './resetPassword.json';
import { default as _setNewPassword } from './setNewPassword.json';
import { default as _settings } from './settings.json';
import { default as _signup } from './signup.json';
import { default as _integrations } from './integrations.json';
import { default as _generalSettings } from './generalSettings.json';
import { default as _teamsSettings } from './teamsSettings.json';

import { default as _campaign } from './campaign.json';

export default {
  ..._agentMgmt,
  ..._cannedMgmt,
  ..._chatlist,
  ..._contact,
  ..._conversation,
  ..._inboxMgmt,
  ..._login,
  ..._report,
  ..._labelsMgmt,
  ..._resetPassword,
  ..._setNewPassword,
  ..._settings,
  ..._signup,
  ..._integrations,
  ..._generalSettings,
  ..._teamsSettings,
  ..._campaign,
};
