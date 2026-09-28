import { ref } from 'vue';
import { shallowMount } from '@vue/test-utils';
import ViewAllConversations from '../ViewAllConversations.vue';
import { CONTACT_CONVERSATION_NAVIGATION } from 'dashboard/composables/useContactConversationNavigation';

const isOnExpandedLayout = ref(false);
const isOnFolderView = ref(false);
const route = { name: 'inbox_conversation' };

vi.mock('vue-router', () => ({
  useRoute: () => route,
}));

vi.mock('dashboard/composables/store', () => ({
  useMapGetter: () => ref({ id: 13 }),
}));

vi.mock('dashboard/composables/useUISettings', () => ({
  useUISettings: () => ({ isOnExpandedLayout }),
}));

vi.mock('dashboard/composables/useConversationRoutePath', () => ({
  useConversationRoutePath: () => ({
    buildConversationPath: id => `/conversations/${id}`,
    buildConversationListPath: () => '/conversations',
    isOnFolderView,
  }),
}));

const mountComponent = navigation =>
  shallowMount(ViewAllConversations, {
    global: {
      provide: { [CONTACT_CONVERSATION_NAVIGATION]: navigation },
      mocks: { $t: key => key },
    },
  });

describe('ViewAllConversations', () => {
  let navigation;

  beforeEach(() => {
    route.name = 'inbox_conversation';
    isOnExpandedLayout.value = false;
    isOnFolderView.value = false;
    navigation = { hasHistory: ref(true), viewContactHistory: vi.fn() };
  });

  it('is hidden without history or without a conversation view around it', () => {
    navigation.hasHistory.value = false;
    expect(mountComponent(navigation).find('button').exists()).toBe(false);
    expect(mountComponent(null).find('button').exists()).toBe(false);
  });

  it('moves from the inbox view to the conversation view with the same thread', async () => {
    route.name = 'inbox_view_conversation';
    const wrapper = mountComponent(navigation);
    await wrapper.find('button').trigger('click');

    expect(navigation.viewContactHistory).toHaveBeenCalledWith({
      conversationId: 13,
      path: '/conversations/13',
    });
  });

  it('keeps the open thread while scoping the list', async () => {
    const wrapper = mountComponent(navigation);
    await wrapper.find('button').trigger('click');

    expect(navigation.viewContactHistory).toHaveBeenCalledWith({
      conversationId: 13,
      path: null,
    });
  });

  it('leaves the folder scope with the same thread', async () => {
    isOnFolderView.value = true;
    const wrapper = mountComponent(navigation);
    await wrapper.find('button').trigger('click');

    expect(navigation.viewContactHistory).toHaveBeenCalledWith({
      conversationId: 13,
      path: '/conversations/13',
    });
  });

  it('moves to the list on the expanded layout', async () => {
    isOnExpandedLayout.value = true;
    const wrapper = mountComponent(navigation);
    await wrapper.find('button').trigger('click');

    expect(navigation.viewContactHistory).toHaveBeenCalledWith({
      path: '/conversations',
    });
  });
});
