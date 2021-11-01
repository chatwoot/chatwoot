import { shallowMount, createLocalVue } from '@vue/test-utils';
import attributeMixin from '../attributeMixin';
import Vuex from 'vuex';
import attributeFixtures from './attributeFixtures';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('attributeMixin', () => {
  let getters;
  let actions;
  let store;

  beforeEach(() => {
    actions = { updateUISettings: jest.fn(), toggleSidebarUIState: jest.fn() };
    getters = {
      getSelectedChat: () => ({
        id: 7165,
        custom_attributes: {
          product_id: 2021,
        },
      }),
      getCurrentAccountId: () => 1,
    };
    store = new Vuex.Store({ actions, getters });
  });

  it('returns currently selected conversation custom attributes', () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [attributeMixin],
    };
    const wrapper = shallowMount(Component, { store, localVue });
    expect(wrapper.vm.customAttributes).toEqual({
      product_id: 2021,
    });
  });

  it('returns currently selected conversation id', () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [attributeMixin],
    };
    const wrapper = shallowMount(Component, { store, localVue });
    expect(wrapper.vm.conversationId).toEqual(7165);
  });

  it('returns filtered attributes from conversation custom attributes', () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [attributeMixin],
      computed: {
        attributes() {
          return attributeFixtures;
        },
      },
    };
    const wrapper = shallowMount(Component, { store, localVue });
    expect(wrapper.vm.filteredAttributes).toEqual([
      {
        attribute_description: 'Product identifier',
        attribute_display_name: 'Product id',
        attribute_display_type: 'number',
        attribute_key: 'product_id',
        attribute_model: 'conversation_attribute',
        created_at: '2021-09-16T13:06:47.329Z',
        default_value: null,
        icon: 'ion-calculator',
        id: 10,
        updated_at: '2021-09-22T10:42:25.873Z',
        value: 2021,
      },
    ]);
  });

  it('return icon if attribute type passed correctly', () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [attributeMixin],
    };
    const wrapper = shallowMount(Component, { store, localVue });
    expect(wrapper.vm.attributeIcon('date')).toBe('ion-calendar');
    expect(wrapper.vm.attributeIcon()).toBe('ion-edit');
  });
});
