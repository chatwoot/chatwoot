import { shallowMount, createLocalVue } from '@vue/test-utils';
import uiSettingsMixin, {
  DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER,
  DEFAULT_CONTACT_SIDEBAR_ITEMS_ORDER,
} from '../uiSettings';
import Vuex from 'vuex';
const localVue = createLocalVue();
localVue.use(Vuex);

describe('uiSettingsMixin', () => {
  let getters;
  let actions;
  let store;

  beforeEach(() => {
    actions = { updateUISettings: jest.fn(), toggleSidebarUIState: jest.fn() };
    getters = {
      getUISettings: () => ({
        display_rich_content_editor: false,
        enter_to_send_enabled: false,
        is_ct_labels_open: true,
        conversation_sidebar_items_order: DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER,
        contact_sidebar_items_order: DEFAULT_CONTACT_SIDEBAR_ITEMS_ORDER,
      }),
    };
    store = new Vuex.Store({ actions, getters });
  });

  it('returns uiSettings', () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [uiSettingsMixin],
    };
    const wrapper = shallowMount(Component, { store, localVue });
    expect(wrapper.vm.uiSettings).toEqual({
      display_rich_content_editor: false,
      enter_to_send_enabled: false,
      is_ct_labels_open: true,
      conversation_sidebar_items_order: DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER,
      contact_sidebar_items_order: DEFAULT_CONTACT_SIDEBAR_ITEMS_ORDER,
    });
  });

  describe('#updateUISettings', () => {
    it('dispatches store actions correctly', () => {
      const Component = {
        render() {},
        title: 'TestComponent',
        mixins: [uiSettingsMixin],
      };
      const wrapper = shallowMount(Component, { store, localVue });
      wrapper.vm.updateUISettings({ enter_to_send_enabled: true });
      expect(actions.updateUISettings).toHaveBeenCalledWith(
        expect.anything(),
        {
          uiSettings: {
            display_rich_content_editor: false,
            enter_to_send_enabled: true,
            is_ct_labels_open: true,
            conversation_sidebar_items_order: DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER,
            contact_sidebar_items_order: DEFAULT_CONTACT_SIDEBAR_ITEMS_ORDER,
          },
        },
        undefined
      );
    });
  });

  describe('#toggleSidebarUIState', () => {
    it('dispatches store actions correctly', () => {
      const Component = {
        render() {},
        title: 'TestComponent',
        mixins: [uiSettingsMixin],
      };
      const wrapper = shallowMount(Component, { store, localVue });
      wrapper.vm.toggleSidebarUIState('is_ct_labels_open');
      expect(actions.updateUISettings).toHaveBeenCalledWith(
        expect.anything(),
        {
          uiSettings: {
            display_rich_content_editor: false,
            enter_to_send_enabled: false,
            is_ct_labels_open: false,
            conversation_sidebar_items_order: DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER,
            contact_sidebar_items_order: DEFAULT_CONTACT_SIDEBAR_ITEMS_ORDER,
          },
        },
        undefined
      );
    });
  });

  describe('#isContactSidebarItemOpen', () => {
    it('returns correct values', () => {
      const Component = {
        render() {},
        title: 'TestComponent',
        mixins: [uiSettingsMixin],
      };
      const wrapper = shallowMount(Component, { store, localVue });
      expect(wrapper.vm.isContactSidebarItemOpen('is_ct_labels_open')).toEqual(
        true
      );
      expect(
        wrapper.vm.isContactSidebarItemOpen('is_ct_prev_conv_open')
      ).toEqual(false);
    });
  });

  describe('#conversationSidebarItemsOrder', () => {
    it('returns correct values', () => {
      const Component = {
        render() {},
        title: 'TestComponent',
        mixins: [uiSettingsMixin],
      };
      const wrapper = shallowMount(Component, { store, localVue });
      expect(wrapper.vm.conversationSidebarItemsOrder).toEqual([
        { name: 'conversation_actions' },
        { name: 'conversation_info' },
        { name: 'contact_attributes' },
        { name: 'previous_conversation' },
      ]);
    });
  });
  describe('#contactSidebarItemsOrder', () => {
    it('returns correct values', () => {
      const Component = {
        render() {},
        title: 'TestComponent',
        mixins: [uiSettingsMixin],
      };
      const wrapper = shallowMount(Component, { store, localVue });
      expect(wrapper.vm.contactSidebarItemsOrder).toEqual([
        { name: 'contact_attributes' },
        { name: 'contact_labels' },
        { name: 'previous_conversation' },
      ]);
    });
  });
});
