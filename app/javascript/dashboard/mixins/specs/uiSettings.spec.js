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
    actions = { updateUISettings: jest.fn() };
    getters = {
      getUISettings: () => ({
        display_rich_content_editor: false,
        enter_to_send_enabled: false,
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
    });
  });

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
        },
      },
      undefined
    );
  });
});
