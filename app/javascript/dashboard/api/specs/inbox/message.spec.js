import messageAPI, { buildCreatePayload } from '../../inbox/message';
import ApiClient from '../../ApiClient';

describe('#ConversationAPI', () => {
  it('creates correct instance', () => {
    expect(messageAPI).toBeInstanceOf(ApiClient);
    expect(messageAPI).toHaveProperty('get');
    expect(messageAPI).toHaveProperty('show');
    expect(messageAPI).toHaveProperty('create');
    expect(messageAPI).toHaveProperty('update');
    expect(messageAPI).toHaveProperty('delete');
    expect(messageAPI).toHaveProperty('getPreviousMessages');
  });

  describe('API calls', () => {
    const originalAxios = window.axios;
    const axiosMock = {
      post: vi.fn(() => Promise.resolve()),
      get: vi.fn(() => Promise.resolve()),
      patch: vi.fn(() => Promise.resolve()),
      delete: vi.fn(() => Promise.resolve()),
    };

    beforeEach(() => {
      window.axios = axiosMock;
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    it('#getPreviousMessages', () => {
      messageAPI.getPreviousMessages({
        conversationId: 12,
        before: 4573,
      });
      expect(axiosMock.get).toHaveBeenCalledWith(
        `/api/v1/conversations/12/messages`,
        {
          params: {
            before: 4573,
          },
        }
      );
    });
  });
  describe('#buildCreatePayload', () => {
    it('builds form payload if file is available', () => {
      const templateParams = {
        name: 'ticket_status_updated',
        processed_params: {
          body: { name: 'John' },
          buttons: [{ type: 'url', parameter: 'track-123' }],
        },
      };
      const formPayload = buildCreatePayload({
        message: 'test content',
        echoId: 12,
        isPrivate: true,
        contentAttributes: { in_reply_to: 12 },
        files: [new Blob(['test-content'], { type: 'application/pdf' })],
        templateParams,
      });
      expect(formPayload).toBeInstanceOf(FormData);
      expect(formPayload.get('content')).toEqual('test content');
      expect(formPayload.get('echo_id')).toEqual('12');
      expect(formPayload.get('private')).toEqual('true');
      expect(formPayload.get('cc_emails')).toEqual('');
      expect(formPayload.get('bcc_emails')).toEqual('');
      expect(formPayload.get('content_attributes')).toEqual(
        '{"in_reply_to":12}'
      );
      expect(formPayload.get('template_params')).toEqual(null);
      expect(formPayload.get('template_params[name]')).toEqual(
        'ticket_status_updated'
      );
      expect(
        formPayload.get('template_params[processed_params][body][name]')
      ).toEqual('John');
      expect(
        formPayload.get('template_params[processed_params][buttons][][type]')
      ).toEqual('url');
      expect(
        formPayload.get(
          'template_params[processed_params][buttons][][parameter]'
        )
      ).toEqual('track-123');
      expect(
        Array.from(formPayload.keys()).some(key => key.includes('[buttons][0]'))
      ).toBe(false);
    });

    it('builds object payload if file is not available', () => {
      expect(
        buildCreatePayload({
          message: 'test content',
          isPrivate: false,
          echoId: 12,
          contentAttributes: { in_reply_to: 12 },
        })
      ).toEqual({
        content: 'test content',
        private: false,
        echo_id: 12,
        content_attributes: { in_reply_to: 12 },
        cc_emails: '',
        bcc_emails: '',
        to_emails: '',
        template_params: undefined,
      });
    });

    it('preserves sparse button indices in multipart template params', () => {
      const buttons = [];
      buttons[1] = { type: 'url', parameter: 'track-123' };

      const formPayload = buildCreatePayload({
        message: 'test content',
        echoId: 12,
        isPrivate: true,
        files: [new Blob(['test-content'], { type: 'application/pdf' })],
        templateParams: {
          name: 'ticket_status_updated',
          processed_params: { buttons },
        },
      });

      expect(formPayload).toBeInstanceOf(FormData);
      expect(
        formPayload.getAll('template_params[processed_params][buttons][]')
      ).toEqual(['']);
      expect(
        formPayload.getAll('template_params[processed_params][buttons][][type]')
      ).toEqual(['url']);
      expect(
        formPayload.getAll(
          'template_params[processed_params][buttons][][parameter]'
        )
      ).toEqual(['track-123']);
    });
  });
});
