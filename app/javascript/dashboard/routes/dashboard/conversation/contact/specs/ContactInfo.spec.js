import { shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import ContactInfo from '../ContactInfo.vue';

const ContactInfoRowStub = {
  name: 'ContactInfoRow',
  props: {
    icon: String,
    editable: Boolean,
  },
  template: '<div />',
};

const componentStubs = {
  ContactInfoRow: ContactInfoRowStub,
  Avatar: { template: '<div />' },
  SocialIcons: { template: '<div />' },
  EditContact: { template: '<div />' },
  ContactMergeModal: { template: '<div />' },
  ContactDeleteModal: { template: '<div />' },
  ComposeConversation: { template: '<div><slot name="trigger" /></div>' },
  NextButton: { template: '<button />' },
  VoiceCallButton: { template: '<button />' },
  InlineInput: { template: '<input />' },
};

describe('ContactInfo', () => {
  it('keeps the empty email row editable', () => {
    const store = createStore({
      getters: {
        getCurrentRole: () => 'administrator',
        'contacts/getUIFlags': () => ({}),
      },
      actions: {
        'contacts/fetchContactableInbox': vi.fn(),
      },
    });

    const wrapper = shallowMount(ContactInfo, {
      props: {
        contact: {
          id: 1,
          name: 'John Doe',
          email: '',
          emails: [],
          additional_attributes: {},
        },
      },
      global: {
        mocks: {
          $t: key => key,
          $route: { params: { accountId: 1 } },
        },
        plugins: [store],
        stubs: componentStubs,
      },
    });

    const emailRow = wrapper
      .findAllComponents(ContactInfoRowStub)
      .find(row => row.props('icon') === 'mail');

    expect(emailRow.props('editable')).toBe(true);
  });
});
