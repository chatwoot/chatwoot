export const getTimelineEntries = panel =>
  Array.from(
    panel.querySelectorAll('[data-message-id], [id^="campaign-recipient-"]')
  );

export const getUnreadScrollTop = (panel, unreadMessage, viewportHeight) =>
  panel.scrollTop +
  unreadMessage.getBoundingClientRect().top -
  panel.getBoundingClientRect().top -
  viewportHeight / 2;

export const captureTimelineAnchor = (panel, messageId) => {
  const entries = getTimelineEntries(panel);
  const panelTop = panel.getBoundingClientRect().top;
  const anchor =
    entries.find(entry => entry.id === `message${messageId}`) ||
    entries.find(entry => entry.getBoundingClientRect().bottom > panelTop);
  const offset = anchor?.getBoundingClientRect().top;

  return () => {
    if (!anchor || !panel.contains(anchor)) return;
    panel.scrollTop += anchor.getBoundingClientRect().top - offset;
  };
};
