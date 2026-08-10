import { buildInboxData } from '../channelActions';

describe('#buildInboxData', () => {
  it('serializes nested additional_attributes as bracketed form fields', () => {
    const formData = buildInboxData({
      name: 'Test inbox',
      channel: {
        webhook_url: 'https://example.com',
        additional_attributes: { include_private_notes: true },
      },
    });

    expect(
      formData.get('channel[additional_attributes][include_private_notes]')
    ).toBe('true');
    expect(formData.get('channel[webhook_url]')).toBe('https://example.com');
    expect(formData.get('channel[additional_attributes]')).toBeNull();
  });

  it('does not append additional_attributes fields when absent', () => {
    const formData = buildInboxData({
      name: 'Test inbox',
      channel: { webhook_url: 'https://example.com' },
    });

    expect(
      formData.get('channel[additional_attributes][include_private_notes]')
    ).toBeNull();
  });
});
