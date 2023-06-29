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

export function generateTranslationPayload(auditLogItem, agentList) {
  let translationPayload = {
    agentName: getAgentName(auditLogItem.user_id, agentList),
    id: auditLogItem.auditable_id,
  };

  const auditableType = auditLogItem.auditable_type.toLowerCase();
  const action = auditLogItem.action.toLowerCase();

  if (auditableType === 'accountuser') {
    if (action === 'create') {
      translationPayload = handleAccountUserCreate(
        auditLogItem,
        translationPayload,
        agentList
      );
    }

    if (action === 'update') {
      translationPayload = handleAccountUserUpdate(
        auditLogItem,
        translationPayload,
        agentList
      );
    }
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
