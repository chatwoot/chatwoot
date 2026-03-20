import ScheduledMessagesAPI, {
  buildScheduledMessagePayload,
} from '../scheduledMessages';

describe('#ScheduledMessagesAPI', () => {
  describe('#buildScheduledMessagePayload', () => {
    it('builds object payload without attachment or FormData with attachment', () => {
      const objectPayload = buildScheduledMessagePayload({
        content: 'Hello',
        scheduledAt: '2025-01-01T10:00:00Z',
        status: 'pending',
      });

      expect(objectPayload).toEqual({
        content: 'Hello',
        scheduled_at: '2025-01-01T10:00:00Z',
        status: 'pending',
        private: undefined,
        template_params: undefined,
        content_attributes: undefined,
        additional_attributes: undefined,
      });

      const formPayload = buildScheduledMessagePayload({
        content: 'Hello',
        attachment: new Blob(['test'], { type: 'text/plain' }),
      });

      expect(formPayload).toBeInstanceOf(FormData);
      expect(formPayload.get('content')).toEqual('Hello');
    });
  });

  describe('API calls', () => {
    const originalAxios = window.axios;
    const originalPathname = window.location.pathname;
    const axiosMock = Object.assign(
      vi.fn(() => Promise.resolve()),
      { delete: vi.fn(() => Promise.resolve()) }
    );

    beforeEach(() => {
      axiosMock.mockClear();
      axiosMock.delete.mockClear();
      window.axios = axiosMock;
      window.history.pushState({}, '', '/app/accounts/1/inbox');
    });

    afterEach(() => {
      window.axios = originalAxios;
      window.history.pushState({}, '', originalPathname);
    });

    it('calls correct endpoints for create, update, and delete', () => {
      ScheduledMessagesAPI.create(12, { content: 'Hello' });
      expect(axiosMock).toHaveBeenCalledWith(
        expect.objectContaining({
          method: 'post',
          url: '/api/v1/accounts/1/conversations/12/scheduled_messages',
        })
      );

      ScheduledMessagesAPI.update(12, 7, { status: 'pending' });
      expect(axiosMock).toHaveBeenCalledWith(
        expect.objectContaining({
          method: 'patch',
          url: '/api/v1/accounts/1/conversations/12/scheduled_messages/7',
        })
      );

      ScheduledMessagesAPI.delete(12, 7);
      expect(axiosMock.delete).toHaveBeenCalledWith(
        '/api/v1/accounts/1/conversations/12/scheduled_messages/7'
      );
    });
  });
});
