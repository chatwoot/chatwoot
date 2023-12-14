import replyActionApi from '../../inbox/conversation';
import ApiClient from '../../ApiClient';
import describeWithAPIMock from '../apiSpecHelper';

describe('#ReplyActionApi', () => {
  it('creates correct instance', () => {
    expect(replyActionApi).toBeInstanceOf(ApiClient);
    expect(replyActionApi).toHaveProperty('get');
    expect(replyActionApi).toHaveProperty('update');
    expect(replyActionApi).toHaveProperty('delete');
  });

  describeWithAPIMock('API calls', context => {
    it('#get', () => {
      replyActionApi.get({
        conversationId: 2,
      });
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        `/api/v1/conversations/2/reply_action`
      );
    });

    it('#update', () => {
      replyActionApi.update({
        conversationId: 45,
        message: 'Hello',
      });
      expect(context.axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/conversations/45/reply_action',
        {
          message: 'Hello',
        }
      );
    });

    it('#delete', () => {
      replyActionApi.delete({
        conversationId: 12,
      });
      expect(context.axiosMock.delete).toHaveBeenCalledWith(
        `/api/v1/conversations/12/reply_action`
      );
    });
  });
});
