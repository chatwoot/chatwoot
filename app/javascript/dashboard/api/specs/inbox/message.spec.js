import messageAPI, { buildCreatePayload } from '../../inbox/message';
import ApiClient from '../../ApiClient';
import describeWithAPIMock from '../apiSpecHelper';

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

  describeWithAPIMock('API calls', context => {
    it('#getPreviousMessages', () => {
      messageAPI.getPreviousMessages({
        conversationId: 12,
        before: 4573,
      });
      expect(context.axiosMock.get).toHaveBeenCalledWith(
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
      const formPayload = buildCreatePayload({
        message: 'test content',
        echoId: 12,
        isPrivate: true,

        file: new Blob(['test-content'], { type: 'application/pdf' }),
      });
      expect(formPayload).toBeInstanceOf(FormData);
      expect(formPayload.get('content')).toEqual('test content');
      expect(formPayload.get('echo_id')).toEqual('12');
      expect(formPayload.get('private')).toEqual('true');
      expect(formPayload.get('cc_emails')).toEqual('');
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
        bcc_emails: '',
        cc_emails: '',
      });
    });
  });
});
