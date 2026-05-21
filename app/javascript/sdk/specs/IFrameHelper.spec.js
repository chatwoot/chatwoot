import { IFrameHelper } from '../IFrameHelper';

describe('#IFrameHelper', () => {
  describe('#resetTransientView', () => {
    let toggleBubbleSpy;

    beforeEach(() => {
      window.$chatwoot = { isOpen: true };
      document.body.innerHTML = `
        <div class="woot-widget-holder has-unread-view">
          <iframe id="chatwoot_live_chat_widget" style="height: 293px !important"></iframe>
        </div>
      `;
      toggleBubbleSpy = vi
        .spyOn(IFrameHelper.events, 'toggleBubble')
        .mockImplementation(() => {});
    });

    afterEach(() => {
      toggleBubbleSpy.mockRestore();
      document.body.innerHTML = '';
      delete window.$chatwoot;
    });

    it('closes and restores iframe height when the transient unread view is visible', () => {
      IFrameHelper.events.resetTransientView();

      expect(
        document
          .querySelector('.woot-widget-holder')
          .classList.contains('has-unread-view')
      ).toBe(false);
      expect(
        document
          .getElementById('chatwoot_live_chat_widget')
          .style.getPropertyValue('height')
      ).toBe('100%');
      expect(toggleBubbleSpy).toHaveBeenCalledWith('close');
    });

    it('leaves the widget untouched when no transient view is visible', () => {
      document
        .querySelector('.woot-widget-holder')
        .classList.remove('has-unread-view');

      IFrameHelper.events.resetTransientView();

      expect(
        document
          .getElementById('chatwoot_live_chat_widget')
          .style.getPropertyValue('height')
      ).toBe('293px');
      expect(toggleBubbleSpy).not.toHaveBeenCalled();
    });
  });
});
