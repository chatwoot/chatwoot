import { shallowMount, createLocalVue } from '@vue/test-utils';
import uiSettingsMixin from '../uiSettings';
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
});
