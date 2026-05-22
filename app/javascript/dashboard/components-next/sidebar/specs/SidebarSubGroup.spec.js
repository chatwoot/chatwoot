import { mount } from '@vue/test-utils';
import { ref } from 'vue';
import SidebarSubGroup from '../SidebarSubGroup.vue';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { provideSidebarContext } from '../provider';

vi.mock('dashboard/composables/store', () => ({
  useMapGetter: () => ref(1),
}));

vi.mock('dashboard/composables/usePolicy', () => ({
  usePolicy: () => ({
    shouldShow: () => true,
  }),
}));

vi.mock('vue-router', () => ({
  useRouter: () => ({
    resolve: () => ({ path: '/' }),
    getRoutes: () => [],
  }),
}));

const children = [
  {
    name: 'Sales-1',
    label: 'Sales',
    to: { name: 'team_conversations' },
  },
];

const mountSubGroup = props => {
  return mount(
    {
      components: { SidebarSubGroup },
      setup() {
        provideSidebarContext({});
      },
      template: '<SidebarSubGroup v-bind="$attrs" />',
    },
    {
      attrs: {
        name: 'Conversation:Teams',
        label: 'Teams',
        icon: 'i-lucide-users',
        children,
        isExpanded: true,
        collapsible: true,
        ...props,
      },
      global: {
        stubs: {
          SidebarGroupLeaf: {
            props: ['label'],
            template: '<li class="sidebar-leaf">{{ label }}</li>',
          },
        },
      },
    }
  );
};

describe('SidebarSubGroup', () => {
  let localStorageStore;

  beforeEach(() => {
    localStorageStore = {};
    Object.defineProperty(window, 'localStorage', {
      value: {
        getItem: key => localStorageStore[key] || null,
        setItem: (key, value) => {
          localStorageStore[key] = String(value);
        },
        removeItem: key => {
          delete localStorageStore[key];
        },
        clear: () => {
          localStorageStore = {};
        },
      },
      configurable: true,
    });

    window.localStorage.clear();
  });

  it('keeps collapsible sections expanded by default', () => {
    const wrapper = mountSubGroup();

    expect(wrapper.find('button').attributes('aria-expanded')).toBe('true');
    expect(wrapper.find('.sidebar-leaf').isVisible()).toBe(true);
  });

  it('minimizes the section and stores it by account and section name', async () => {
    const wrapper = mountSubGroup();

    await wrapper.find('button').trigger('click');

    const storedSections = JSON.parse(
      window.localStorage.getItem(LOCAL_STORAGE_KEYS.SIDEBAR_MINIMIZED_SECTIONS)
    );
    expect(wrapper.find('button').attributes('aria-expanded')).toBe('false');
    expect(wrapper.find('.sidebar-leaf').isVisible()).toBe(false);
    expect(storedSections).toEqual({ '1:Conversation:Teams': true });
  });

  it('uses the stored minimized state when mounted again', () => {
    window.localStorage.setItem(
      LOCAL_STORAGE_KEYS.SIDEBAR_MINIMIZED_SECTIONS,
      JSON.stringify({ '1:Conversation:Teams': true })
    );

    const wrapper = mountSubGroup();

    expect(wrapper.find('button').attributes('aria-expanded')).toBe('false');
    expect(wrapper.find('.sidebar-leaf').isVisible()).toBe(false);
  });
});
