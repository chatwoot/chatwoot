import messageAPI from '../../inbox/message';
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
    let originalAxios = null;
    let axiosMock = null;
    beforeEach(() => {
      originalAxios = window.axios;
      axiosMock = {
        post: jest.fn(() => Promise.resolve()),
        get: jest.fn(() => Promise.resolve()),
      };
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
});
