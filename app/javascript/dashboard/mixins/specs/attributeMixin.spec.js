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
        meta: {
          sender: {
            id: 1212,
          },
        },
      }),
      getCurrentAccountId: () => 1,
      attributeType: () => 'conversation_attribute',
    };
    store = new Vuex.Store({ actions, getters });
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
        contact() {
          return {
            id: 7165,
            custom_attributes: {
              product_id: 2021,
            },
          };
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
        icon: 'fluent-calculator',
        id: 10,
        updated_at: '2021-09-22T10:42:25.873Z',
        value: 2021,
      },
    ]);
  });

  it('return display type if attribute passed', () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [attributeMixin],
    };
    const wrapper = shallowMount(Component, { store, localVue });
    expect(wrapper.vm.attributeDisplayType('date')).toBe('text');
    expect(
      wrapper.vm.attributeDisplayType('https://www.chatwoot.com/pricing')
    ).toBe('link');
    expect(wrapper.vm.attributeDisplayType(9988)).toBe('number');
  });

  it('return true if number is passed', () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [attributeMixin],
    };
    const wrapper = shallowMount(Component, { store, localVue });
    expect(wrapper.vm.isAttributeNumber(9988)).toBe(true);
  });

  it('returns currently selected contact', () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [attributeMixin],
      computed: {
        contact() {
          return {
            id: 7165,
            custom_attributes: {
              product_id: 2021,
            },
          };
        },
      },
    };
    const wrapper = shallowMount(Component, { store, localVue });
    expect(wrapper.vm.contact).toEqual({
      id: 7165,
      custom_attributes: {
        product_id: 2021,
      },
    });
  });

  it('returns currently selected contact id', () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [attributeMixin],
    };
    const wrapper = shallowMount(Component, { store, localVue });
    expect(wrapper.vm.contactIdentifier).toEqual(1212);
  });

  it('returns currently selected conversation custom attributes', () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [attributeMixin],
      computed: {
        contact() {
          return {
            id: 7165,
            custom_attributes: {
              product_id: 2021,
            },
          };
        },
      },
    };
    const wrapper = shallowMount(Component, { store, localVue });
    expect(wrapper.vm.customAttributes).toEqual({
      product_id: 2021,
    });
  });

  it('returns currently selected contact custom attributes', () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [attributeMixin],
      computed: {
        contact() {
          return {
            id: 7165,
            custom_attributes: {
              cloudCustomer: true,
            },
          };
        },
      },
    };
    const wrapper = shallowMount(Component, { store, localVue });
    expect(wrapper.vm.customAttributes).toEqual({
      cloudCustomer: true,
    });
  });
});
