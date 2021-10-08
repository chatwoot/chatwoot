export const findPendingMessageIndex = (chat, message) => {
  const { echo_id: tempMessageId } = message;
  return chat.messages.findIndex(
    m => m.id === message.id || m.id === tempMessageId
  );
};

const filterByStatus = (chatStatus, filterStatus) =>
  filterStatus === 'all' ? true : chatStatus === filterStatus;

export const applyPageFilters = (conversation, filters) => {
  const { inboxId, status, labels = [], teamId } = filters;
  const {
    status: chatStatus,
    inbox_id: chatInboxId,
    labels: chatLabels = [],
    meta = {},
  } = conversation;
  const team = meta.team || {};
  const { id: chatTeamId } = team;

  let shouldFilter = filterByStatus(chatStatus, status);
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
