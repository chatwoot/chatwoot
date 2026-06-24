export const inferAssigneeType = assignee => {
  if (!assignee?.id) return null;

  if (
    assignee.assignee_type === 'AgentBot' ||
    assignee.assignee_type === 'User'
  ) {
    return assignee.assignee_type;
  }

  if (
    assignee.role === 'agent_bot' ||
    assignee.bot_type !== undefined ||
    assignee.outgoing_url !== undefined
  ) {
    return 'AgentBot';
  }

  return 'User';
};

export const getConversationAssigneeType = meta => {
  if (!meta?.assignee?.id) return null;

  if (meta.assignee_type === 'AgentBot' || meta.assignee_type === 'User') {
    return meta.assignee_type;
  }

  return inferAssigneeType(meta.assignee);
};

export const isHumanAssigneeMeta = meta =>
  getConversationAssigneeType(meta) === 'User';

export const isBotAssigneeMeta = meta =>
  getConversationAssigneeType(meta) === 'AgentBot';

export const isBotHandledConversation = conversation => {
  if (!conversation) return false;
  if (isHumanAssigneeMeta(conversation.meta)) return false;

  return (
    Boolean(conversation.bot_handling) || isBotAssigneeMeta(conversation.meta)
  );
};

export const isNonHumanAssignedConversation = conversation =>
  !isHumanAssigneeMeta(conversation?.meta);

export const getInboxBotAgent = agents =>
  (agents || []).find(
    agent =>
      agent.assignee_type === 'AgentBot' ||
      agent.role === 'agent_bot' ||
      agent.bot_type !== undefined ||
      agent.outgoing_url !== undefined
  ) || null;

export const isAgentBotAssigneeMeta = (meta, inboxBotId = null) => {
  const { assignee, assignee_type: assigneeType } = meta || {};
  if (!assignee?.id) return false;

  if (assigneeType === 'AgentBot') {
    return inboxBotId == null || Number(assignee.id) === Number(inboxBotId);
  }

  if (
    assignee.role === 'agent_bot' ||
    assignee.bot_type !== undefined ||
    assignee.outgoing_url !== undefined
  ) {
    return inboxBotId == null || Number(assignee.id) === Number(inboxBotId);
  }

  return false;
};

export const isClearAssigneeSelection = agent =>
  !agent || agent.id === 0 || agent.id === null;

export const isSameAssignee = (left, right) => {
  if (!left?.id || !right?.id) return false;

  return (
    Number(left.id) === Number(right.id) &&
    inferAssigneeType(left) === inferAssigneeType(right)
  );
};

export const isCurrentUserAssigneeMeta = (meta, currentUser) => {
  if (!isHumanAssigneeMeta(meta) || !currentUser?.id) return false;

  return Number(meta.assignee.id) === Number(currentUser.id);
};

export const getAssigneeSelectionKey = assignee => {
  if (!assignee?.id) return 'none';

  return `${inferAssigneeType(assignee)}-${assignee.id}`;
};

export const resolveAssigneeType = assignee =>
  assignee?.assignee_type || inferAssigneeType(assignee);

export const normalizeAssignableAgent = agent => {
  if (!agent) return agent;

  const assignee_type = resolveAssigneeType(agent);
  return assignee_type === agent.assignee_type
    ? agent
    : { ...agent, assignee_type };
};
