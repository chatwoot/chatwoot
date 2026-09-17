export const captureTimelineAnchor = (panel, messageId) => {
  const entries = Array.from(
    panel.querySelectorAll('[id^="message"], [id^="campaign-recipient-"]')
  );
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
