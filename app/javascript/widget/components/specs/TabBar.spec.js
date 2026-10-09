import { mount } from '@vue/test-utils';
import { createStore } from 'vuex';
import TabBar from '../TabBar.vue';

const replace = vi.fn();
let routeName = 'home';

vi.mock('vue-router', () => ({
  useRouter: () => ({ replace }),
  useRoute: () => ({ name: routeName }),
}));

const buildStore = ({ activeUnread = 0, otherUnread = 0 } = {}) =>
  createStore({
    modules: {
      appConfig: {
        namespaced: true,
        getters: { getWidgetColor: () => '#1f93ff' },
      },
      conversation: {
        namespaced: true,
        getters: { getUnreadMessageCount: () => activeUnread },
      },
      conversationList: {
        namespaced: true,
        getters: { getUnreadCount: () => otherUnread },
      },
    },
  });

const mountBar = options =>
  mount(TabBar, { global: { plugins: [buildStore(options)] } });

describe('TabBar', () => {
  beforeEach(() => {
    routeName = 'home';
  });

  it('marks the tab of the current screen as the current page', () => {
    const wrapper = mountBar();
    const [home, messages] = wrapper.findAll('button');
    expect(home.attributes('aria-current')).toBe('page');
    expect(messages.attributes('aria-current')).toBe(undefined);
  });

  it('treats the conversation screens as the messages tab', () => {
    routeName = 'messages';
    const [, messages] = mountBar().findAll('button');
    expect(messages.attributes('aria-current')).toBe('page');
  });

  it('counts the unread conversations on the messages tab', () => {
    const wrapper = mountBar({ activeUnread: 5, otherUnread: 2 });
    const badge = wrapper.find('.sr-only').element.parentElement;
    expect(wrapper.find('[aria-hidden="true"] + .sr-only').text()).toBe(
      'TABS.UNREAD_CONVERSATIONS'
    );
    expect(wrapper.text()).toContain('3');
    expect(badge.classList).toContain('bg-n-slate-12');
    expect(badge.style.backgroundColor).toBe('');
  });

  it('paints the badge in the widget colour while the messages tab is active', () => {
    routeName = 'conversations';
    const badge = mountBar({ otherUnread: 1 }).find('.sr-only').element
      .parentElement;
    expect(badge.classList).not.toContain('bg-n-slate-12');
    expect(badge.style.backgroundColor).toBe('rgb(31, 147, 255)');
  });

  it('shows no badge without unread messages', () => {
    expect(mountBar().find('.sr-only').exists()).toBe(false);
  });

  it('names each icon-only tab for screen readers', () => {
    const [home, messages] = mountBar().findAll('button');
    expect(home.attributes('aria-label')).toBe('TABS.HOME');
    expect(messages.attributes('aria-label')).toBe('TABS.MESSAGES');
  });

  it('navigates to the tab screen', async () => {
    const [, messages] = mountBar().findAll('button');
    await messages.trigger('click');
    expect(replace).toBeCalledWith({ name: 'conversations' });
  });
});
