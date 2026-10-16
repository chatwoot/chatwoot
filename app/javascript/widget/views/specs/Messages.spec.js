import { shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import { IFrameHelper } from 'widget/helpers/utils';
import Messages from '../Messages.vue';

vi.mock('widget/helpers/utils', async importOriginal => {
  const utils = await importOriginal();
  return {
    ...utils,
    IFrameHelper: { ...utils.IFrameHelper, isIFrame: vi.fn() },
  };
});

describe('Messages', () => {
  const setUserLastSeen = vi.fn();
  const mountWith = isWidgetOpen => {
    const store = createStore({
      modules: {
        appConfig: {
          namespaced: true,
          state: { isWidgetOpen },
          getters: { getIsWidgetOpen: state => state.isWidgetOpen },
          mutations: {
            open(state) {
              state.isWidgetOpen = true;
            },
          },
        },
        conversation: {
          namespaced: true,
          getters: { getGroupedConversation: () => [] },
          actions: { setUserLastSeen },
        },
      },
    });
    shallowMount(Messages, { global: { plugins: [store] } });
    return store;
  };

  it('marks the conversation as seen only once the widget is opened', async () => {
    IFrameHelper.isIFrame.mockReturnValue(true);
    const store = mountWith(false);
    expect(setUserLastSeen).not.toBeCalled();

    store.commit('appConfig/open');
    await Promise.resolve();

    expect(setUserLastSeen).toHaveBeenCalledTimes(1);
  });

  it('marks the conversation as seen right away when it is visible', () => {
    IFrameHelper.isIFrame.mockReturnValue(true);
    mountWith(true);
    expect(setUserLastSeen).toHaveBeenCalledTimes(1);
  });

  it('marks the conversation as seen right away outside an iframe', () => {
    IFrameHelper.isIFrame.mockReturnValue(false);
    mountWith(false);
    expect(setUserLastSeen).toHaveBeenCalledTimes(1);
  });
});
