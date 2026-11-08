import { isAutoTranslatedReply } from '../translations';

describe('#isAutoTranslatedReply', () => {
  const translated = {
    source_language: 'fr',
    translations: { en: 'Sorry about that!' },
  };

  it('is true for an agent reply translated before sending', () => {
    expect(
      isAutoTranslatedReply({
        message_type: 1,
        sender: { type: 'user' },
        content_attributes: translated,
      })
    ).toBe(true);
  });

  it('is true for a translated template such as the greeting', () => {
    expect(
      isAutoTranslatedReply({ message_type: 3, content_attributes: translated })
    ).toBe(true);
  });

  it('is false for a bot reply translated for the agent', () => {
    expect(
      isAutoTranslatedReply({
        message_type: 1,
        sender: { type: 'captain_assistant' },
        content_attributes: translated,
      })
    ).toBe(false);
  });

  it('is false for a translation an agent made for themselves', () => {
    expect(
      isAutoTranslatedReply({
        message_type: 1,
        sender: { type: 'user' },
        content_attributes: { translations: { en: 'Hello' } },
      })
    ).toBe(false);
  });
});
