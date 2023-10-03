import draftMessageApi from '../../inbox/conversation';
import ApiClient from '../../ApiClient';
import describeWithAPIMock from '../apiSpecHelper';

describe('#DraftMessageApi', () => {
  it('creates correct instance', () => {
    expect(draftMessageApi).toBeInstanceOf(ApiClient);
    expect(draftMessageApi).toHaveProperty('getDraft');
    expect(conversationAPI).toHaveProperty('updateDraft');
    expect(conversationAPI).toHaveProperty('deleteDraft');
  });

  describeWithAPIMock('API calls', context => {
    it('#getDraft', () => {
      messageAPI.getDraft({
        conversationId: 2
      });
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        `/api/v1/conversations/2/draft_messages`
      );
    });

    it('#updateDraft', () => {
      conversationAPI.updateDraft({
        conversationId: 45,
        message: 'Hello',
      });
      expect(context.axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/conversations/45/draft_messages',
        {
          message: 'Hello',
        }
      );
    });

    it('#deleteDraft', () => {
      messageAPI.deleteDraft({
        conversationId: 12
      });
      expect(context.axiosMock.delete).toHaveBeenCalledWith(
        `/api/v1/conversations/12/draft_messages`
      );
    });
  });
});
