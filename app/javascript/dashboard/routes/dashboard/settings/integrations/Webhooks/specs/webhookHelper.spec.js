import { getEventNamei18n } from '../webhookHelper';

describe('#getEventNamei18n', () => {
  it('returns correct i18n translation text', () => {
    expect(getEventNamei18n('message_created')).toEqual(
      `INTEGRATION_SETTINGS.WEBHOOK.FORM.SUBSCRIPTIONS.EVENTS.MESSAGE_CREATED`
    );
  });
});
