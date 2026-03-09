import { mutations } from '../../appConfig';

describe('#mutations', () => {
  describe('#SET_REFERRER_HOST', () => {
    it('sets referrer host properly', () => {
      const state = { referrerHost: '' };
      mutations.SET_REFERRER_HOST(state, 'www.chatwoot.com');
      expect(state.referrerHost).toEqual('www.chatwoot.com');
    });
  });

  describe('#SET_BUBBLE_VISIBILITY', () => {
    it('sets bubble visibility properly', () => {
      const state = { hideMessageBubble: false };
      mutations.SET_BUBBLE_VISIBILITY(state, true);
      expect(state.hideMessageBubble).toEqual(true);
    });
  });

  describe('#SET_WIDGET_COLOR', () => {
    it('sets widget color properly', () => {
      const state = { widgetColor: '' };
      mutations.SET_WIDGET_COLOR(state, '#00bcd4');
      expect(state.widgetColor).toEqual('#00bcd4');
    });
  });

  describe('#SET_COLOR_SCHEME', () => {
    it('sets dark mode properly', () => {
      const state = { darkMode: 'light' };
      mutations.SET_COLOR_SCHEME(state, 'dark');
      expect(state.darkMode).toEqual('dark');
    });
  });

  describe('#SET_ROUTE_UPDATE_STATE', () => {
    it('sets dark mode properly', () => {
      const state = { isUpdatingRoute: false };
      mutations.SET_ROUTE_UPDATE_STATE(state, true);
      expect(state.isUpdatingRoute).toEqual(true);
    });
  });
});
