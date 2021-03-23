export const findPendingMessageIndex = (chat, message) => {
  const { echo_id: tempMessageId } = message;
  return chat.messages.findIndex(
    m => m.id === message.id || m.id === tempMessageId
  );
};

export const applyPageFilters = (conversation, filters) => {
  const { inboxId, status, labels = [], teamId } = filters;
  const {
    status: chatStatus,
    inbox_id: chatInboxId,
    labels: chatLabels = [],
    meta = {},
  } = conversation;
  const { team = {} } = meta;
  const { id: chatTeamId } = team;
  const filterByStatus = chatStatus === status;
  let shouldFilter = filterByStatus;

  if (inboxId) {
    const filterByInbox = Number(inboxId) === chatInboxId;
    shouldFilter = shouldFilter && filterByInbox;
  }
  if (teamId) {
    const filterByTeam = Number(teamId) === chatTeamId;
    shouldFilter = shouldFilter && filterByTeam;
  }
  if (labels.length) {
    const filterByLabels = labels.every(label => chatLabels.includes(label));
    shouldFilter = shouldFilter && filterByLabels;
  }

  return shouldFilter;
};
