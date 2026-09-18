import { shallowMount } from '@vue/test-utils';
import { ref } from 'vue';

import ContactPanel from '../ContactPanel.vue';

vi.mock('dashboard/composables/store', () => ({
  useMapGetter: vi.fn(key => {
    if (key === 'getSelectedChat') {
      return ref({
        id: 1,
        inbox_id: 1,
        meta: { channel: 'Channel::WebWidget', sender: { id: 1 } },
      });
    }

    if (key === 'contacts/getContact') {
      return ref(() => ({ id: 1, additional_attributes: {} }));
    }

    if (key === 'conversationMetadata/getConversationMetadata') {
      return ref(() => ({ additional_attributes: {} }));
    }

    return ref({});
  }),
  useFunctionGetter: vi.fn(() => ref({ enabled: false })),
  useStore: vi.fn(() => ({
    dispatch: vi.fn(),
  })),
}));

vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: vi.fn(() => ({
    isCloudFeatureEnabled: vi.fn(() => false),
  })),
}));

vi.mock('dashboard/composables/useUISettings', () => ({
  useUISettings: vi.fn(() => ({
    updateUISettings: vi.fn(),
    isContactSidebarItemOpen: vi.fn(() => true),
    conversationSidebarItemsOrder: ref([{ name: 'conversation_info' }]),
    toggleSidebarUIState: vi.fn(),
  })),
}));

const draggableStub = {
  name: 'Draggable',
  props: {
    list: { type: Array, default: () => [] },
    animation: { type: [Number, String], default: 0 },
    ghostClass: { type: String, default: '' },
    handle: { type: String, default: '' },
    delay: { type: Number, default: 0 },
    delayOnTouchOnly: { type: Boolean, default: false },
    touchStartThreshold: { type: Number, default: 0 },
    itemKey: { type: String, default: '' },
  },
  template: '<div />',
};

describe('ContactPanel', () => {
  it('adds touch-only drag delay so mobile scrolling does not immediately reorder items', () => {
    const wrapper = shallowMount(ContactPanel, {
      props: {
        conversationId: 1,
        inboxId: 1,
      },
      global: {
        stubs: {
          Draggable: draggableStub,
          SidebarActionsHeader: true,
          ContactInfo: true,
          AccordionItem: true,
          ConversationInfo: true,
          'woot-feature-toggle': true,
        },
        mocks: {
          $t: key => key,
        },
      },
    });

    const draggable = wrapper.findComponent({ name: 'Draggable' });

    expect(draggable.props('delay')).toBe(200);
    expect(draggable.props('delayOnTouchOnly')).toBe(true);
    expect(draggable.props('touchStartThreshold')).toBe(5);
    expect(draggable.props('handle')).toBe('.drag-handle');
  });
});
