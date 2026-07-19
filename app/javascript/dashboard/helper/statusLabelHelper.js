export const RESOLVED_LABEL_KEYS = ['resolved', 'closed', 'sold', 'finished'];

export const normalizeResolvedLabelKey = key =>
  RESOLVED_LABEL_KEYS.includes(key) ? key : 'resolved';

/**
 * Pure helpers for conversation status labels (API slug stays `resolved`).
 * @param {(key: string, values?: object) => string} t - i18n translate fn
 * @param {string} resolvedLabelKey - account preset
 */
export const getStatusLabel = (t, resolvedLabelKey, status) => {
  if (status === 'resolved') {
    const key = normalizeResolvedLabelKey(resolvedLabelKey);
    return t(`CHAT_LIST.RESOLVED_STATUS_LABELS.${key}`);
  }
  if (!status) return '';
  return t(`CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.${status}.TEXT`);
};

export const getResolveActionLabel = (t, resolvedLabelKey) => {
  const key = normalizeResolvedLabelKey(resolvedLabelKey);
  return t(`CHAT_LIST.RESOLVED_STATUS_ACTIONS.${key}`);
};

export const getMarkAsResolvedLabel = (t, resolvedLabelKey) => {
  const key = normalizeResolvedLabelKey(resolvedLabelKey);
  return t(`CHAT_LIST.RESOLVED_STATUS_MARK_AS.${key}`);
};

/** e.g. "Resolve conversation" / "Mark conversation as sold" */
export const getResolveConversationPhrase = (t, resolvedLabelKey) => {
  const key = normalizeResolvedLabelKey(resolvedLabelKey);
  return t(`CHAT_LIST.RESOLVED_STATUS_CONVERSATION.${key}`);
};

/** Report metric label e.g. "Resolution Count" / "Sold Count" */
export const getResolutionCountLabel = (t, resolvedLabelKey) => {
  const key = normalizeResolvedLabelKey(resolvedLabelKey);
  return t(`CHAT_LIST.RESOLVED_STATUS_REPORT_COUNT.${key}`);
};
