const roleMapping = {
  0: 'agent',
  1: 'administrator',
};

const availabilityMapping = {
  0: 'online',
  1: 'offline',
  2: 'busy',
};

const translationKeys = {
  'automationrule:create': `AUDIT_LOGS.AUTOMATION_RULE.ADD`,
  'automationrule:update': `AUDIT_LOGS.AUTOMATION_RULE.EDIT`,
  'automationrule:destroy': `AUDIT_LOGS.AUTOMATION_RULE.DELETE`,
  'webhook:create': `AUDIT_LOGS.WEBHOOK.ADD`,
  'webhook:update': `AUDIT_LOGS.WEBHOOK.EDIT`,
  'webhook:destroy': `AUDIT_LOGS.WEBHOOK.DELETE`,
  'inbox:create': `AUDIT_LOGS.INBOX.ADD`,
  'inbox:update': `AUDIT_LOGS.INBOX.EDIT`,
  'inbox:destroy': `AUDIT_LOGS.INBOX.DELETE`,
  'user:sign_in': `AUDIT_LOGS.USER_ACTION.SIGN_IN`,
  'user:sign_out': `AUDIT_LOGS.USER_ACTION.SIGN_OUT`,
  'team:create': `AUDIT_LOGS.TEAM.ADD`,
  'team:update': `AUDIT_LOGS.TEAM.EDIT`,
  'team:destroy': `AUDIT_LOGS.TEAM.DELETE`,
  'macro:create': `AUDIT_LOGS.MACRO.ADD`,
  'macro:update': `AUDIT_LOGS.MACRO.EDIT`,
  'macro:destroy': `AUDIT_LOGS.MACRO.DELETE`,
  'accountuser:create': `AUDIT_LOGS.ACCOUNT_USER.ADD`,
  'accountuser:update:self': `AUDIT_LOGS.ACCOUNT_USER.EDIT.SELF`,
  'accountuser:update:other': `AUDIT_LOGS.ACCOUNT_USER.EDIT.OTHER`,
  'inboxmember:create': `AUDIT_LOGS.INBOX_MEMBER.ADD`,
  'inboxmember:destroy': `AUDIT_LOGS.INBOX_MEMBER.REMOVE`,
  'teammember:create': `AUDIT_LOGS.TEAM_MEMBER.ADD`,
  'teammember:destroy': `AUDIT_LOGS.TEAM_MEMBER.REMOVE`,
  'account:update': `AUDIT_LOGS.ACCOUNT.EDIT`,
};

function extractAttrChange(attrChange) {
  if (Array.isArray(attrChange)) {
    return attrChange[attrChange.length - 1];
  }
  return attrChange;
}

export function extractChangedAccountUserValues(auditedChanges) {
  let changes = [];
  let values = [];

  // Check roles
  if (auditedChanges.role && auditedChanges.role.length) {
    changes.push('role');
    values.push(roleMapping[extractAttrChange(auditedChanges.role)]);
  }

  // Check availability
  if (auditedChanges.availability && auditedChanges.availability.length) {
    changes.push('availability');
    values.push(
      availabilityMapping[extractAttrChange(auditedChanges.availability)]
    );
  }

  return { changes, values };
}

function getAgentName(userId, agentList) {
  if (userId === null) {
    return 'System';
  }

  const agentName = agentList.find(agent => agent.id === userId)?.name;

  // If agent does not exist(removed/deleted), return userId
  return agentName || userId;
}

function handleAccountUserCreate(auditLogItem, translationPayload, agentList) {
  translationPayload.invitee = getAgentName(
    auditLogItem.audited_changes.user_id,
    agentList
  );

  const roleKey = auditLogItem.audited_changes.role;
  translationPayload.role = roleMapping[roleKey] || 'unknown'; // 'unknown' as a fallback in case an unrecognized key is provided

  return translationPayload;
}

function handleAccountUserUpdate(auditLogItem, translationPayload, agentList) {
  if (auditLogItem.user_id !== auditLogItem.auditable.user_id) {
    translationPayload.user = getAgentName(
      auditLogItem.auditable.user_id,
      agentList
    );
  }

  const accountUserChanges = extractChangedAccountUserValues(
    auditLogItem.audited_changes
  );
  if (accountUserChanges) {
    translationPayload.attributes = accountUserChanges.changes;
    translationPayload.values = accountUserChanges.values;
  }
  return translationPayload;
}

function setUserInPayload(auditLogItem, translationPayload, agentList) {
  const userIdChange = auditLogItem.audited_changes.user_id;
  if (userIdChange && userIdChange !== undefined) {
    translationPayload.user = getAgentName(userIdChange, agentList);
  }
  return translationPayload;
}

function setTeamIdInPayload(auditLogItem, translationPayload) {
  if (auditLogItem.audited_changes.team_id) {
    translationPayload.team_id = auditLogItem.audited_changes.team_id;
  }
  return translationPayload;
}

function setInboxIdInPayload(auditLogItem, translationPayload) {
  if (auditLogItem.audited_changes.inbox_id) {
    translationPayload.inbox_id = auditLogItem.audited_changes.inbox_id;
  }
  return translationPayload;
}

function handleInboxTeamMember(auditLogItem, translationPayload, agentList) {
  if (auditLogItem.audited_changes) {
    translationPayload = setUserInPayload(
      auditLogItem,
      translationPayload,
      agentList
    );
    translationPayload = setTeamIdInPayload(auditLogItem, translationPayload);
    translationPayload = setInboxIdInPayload(auditLogItem, translationPayload);
  }
  return translationPayload;
}

function handleAccountUser(
  auditLogItem,
  translationPayload,
  agentList,
  action
) {
  if (action === 'create') {
    return handleAccountUserCreate(auditLogItem, translationPayload, agentList);
  }

  if (action === 'update') {
    return handleAccountUserUpdate(auditLogItem, translationPayload, agentList);
  }

  return translationPayload;
}

export function generateTranslationPayload(auditLogItem, agentList) {
  let translationPayload = {
    agentName: getAgentName(auditLogItem.user_id, agentList),
    id: auditLogItem.auditable_id,
  };

  const auditableType = auditLogItem.auditable_type.toLowerCase();
  const action = auditLogItem.action.toLowerCase();

  if (auditableType === 'accountuser') {
    translationPayload = handleAccountUser(
      auditLogItem,
      translationPayload,
      agentList,
      action
    );
  }

  if (auditableType === 'inboxmember' || auditableType === 'teammember') {
    translationPayload = handleInboxTeamMember(
      auditLogItem,
      translationPayload,
      agentList
    );
  }

  return translationPayload;
}

export const generateLogActionKey = auditLogItem => {
  const auditableType = auditLogItem.auditable_type.toLowerCase();
  const action = auditLogItem.action.toLowerCase();
  let logActionKey = `${auditableType}:${action}`;

  if (auditableType === 'accountuser' && action === 'update') {
    logActionKey +=
      auditLogItem.user_id === auditLogItem.auditable.user_id
        ? ':self'
        : ':other';
  }

  return translationKeys[logActionKey] || '';
};
