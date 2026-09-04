const totalMessageHeight = (total, element) => {
  return total + element.scrollHeight;
};

export const calculateScrollTop = (
  conversationPanelHeight,
  parentHeight,
  relevantMessages
) => {
  // add up scrollHeight of a `relevantMessages`
  let combinedMessageScrollHeight = [...relevantMessages].reduce(
    totalMessageHeight,
    0
  );
  return (
    conversationPanelHeight - combinedMessageScrollHeight - parentHeight / 2
  );
};

/**
 * Finds the DOM elements the conversation panel should be scrolled to.
 *
 * Priority: unread messages > label suggestions > last message. Unread
 * messages come first so that the "N unread messages" badge is brought into
 * view, otherwise the panel is scrolled to the end of the list.
 *
 * @param {Object} options
 * @param {HTMLElement} options.container - The scrollable conversation panel
 * @param {Array<{ id: number }>} options.unreadMessages - Messages after the agent's last seen time
 * @param {number} options.unreadMessageCount - Unread count reported for the conversation
 * @returns {HTMLElement[]}
 */
export const getRelevantMessageElements = ({
  container,
  unreadMessages = [],
  unreadMessageCount = 0,
}) => {
  if (!container) return [];

  if (unreadMessageCount > 0) {
    const unreadElements = unreadMessages
      .map(({ id }) => container.querySelector(`#message${id}`))
      .filter(Boolean);
    if (unreadElements.length) return unreadElements;
  }

  // label suggestions are not part of the messages list
  // so we need to handle them separately
  const labelSuggestions = container.querySelector('.label-suggestion');
  if (labelSuggestions) return [labelSuggestions];

  // if there are no unread messages or label suggestions,
  // scroll to the last rendered message bubble
  return Array.from(
    container.querySelectorAll('.message-bubble-container')
  ).slice(-1);
};
