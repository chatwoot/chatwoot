import { MESSAGE_TYPE } from 'widget/helpers/constants';

// Only replies that auto translate translated before sending keep the agent's own text for the contact.
// Bot replies and translations agents made for themselves are not shown in the widget.
export const isAutoTranslatedReply = message => {
  const attributes = message.content_attributes ?? {};
  const translatableSender =
    message.sender?.type === 'user' ||
    message.message_type === MESSAGE_TYPE.TEMPLATE;
  return (
    translatableSender &&
    !!attributes.source_language &&
    !!attributes.translations
  );
};
