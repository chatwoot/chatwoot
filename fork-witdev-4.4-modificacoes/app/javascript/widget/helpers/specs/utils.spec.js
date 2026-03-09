import { IFrameHelper } from '../utils';

vi.mock('vue', () => ({
  config: {
    lang: 'el',
  },
}));

describe('#IFrameHelper', () => {
  describe('#isAValidEvent', () => {
    it('returns if the event is valid', () => {
      expect(
        IFrameHelper.isAValidEvent({
          data: 'chatwoot-widget:{"event":"config-set","locale":"fr","position":"left","hideMessageBubble":false,"showPopoutButton":true}',
        })
      ).toEqual(true);
      expect(
        IFrameHelper.isAValidEvent({
          data: '{"event":"config-set","locale":"fr","position":"left","hideMessageBubble":false,"showPopoutButton":true}',
        })
      ).toEqual(false);
    });
  });
  describe('#getMessage', () => {
    it('returns parsed message', () => {
      expect(
        IFrameHelper.getMessage({
          data: 'chatwoot-widget:{"event":"config-set","locale":"fr","position":"left","hideMessageBubble":false,"showPopoutButton":true}',
        })
      ).toEqual({
        event: 'config-set',
        locale: 'fr',
        position: 'left',
        hideMessageBubble: false,
        showPopoutButton: true,
      });
    });
  });
});
