import { flushPromises, mount } from '@vue/test-utils';
import { createRouter, createMemoryHistory } from 'vue-router';
import { createStore } from 'vuex';
import { withFullI18n } from 'test-i18n';
import ContactAPI from 'dashboard/api/contacts';
import contacts from 'dashboard/store/modules/contacts';
import ContactsIndex from './ContactsIndex.vue';

withFullI18n();

const validSegment = {
  id: 1,
  name: 'Matching Twelve',
  query: {
    payload: [
      {
        attribute_key: 'contract_count',
        filter_operator: 'equal_to',
        values: ['12'],
      },
    ],
  },
};
const invalidSegment = {
  id: 2,
  name: 'Legacy Contains',
  query: {
    payload: [
      {
        attribute_key: 'contract_count',
        filter_operator: 'contains',
        values: ['34'],
      },
    ],
  },
};
const matchingContacts = {
  data: {
    payload: [{ id: 1, name: 'Twelve Contracts' }],
    meta: { count: 1, current_page: 1 },
  },
};

const mountSegment = async id => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {
        path: '/contacts/segments/:segmentId',
        name: 'contacts_dashboard_segments_index',
        component: ContactsIndex,
      },
    ],
  });
  const store = createStore({
    getters: { getUISettings: () => ({}) },
    modules: {
      contacts: { ...contacts, state: () => structuredClone(contacts.state) },
      customViews: {
        namespaced: true,
        getters: {
          getUIFlags: () => ({ isFetching: false }),
          getContactCustomViews: () => [validSegment, invalidSegment],
        },
      },
    },
  });
  await router.push(`/contacts/segments/${id}`);
  const wrapper = mount(ContactsIndex, {
    global: {
      plugins: [router, store],
      stubs: {
        ContactListHeaderWrapper: true,
        ContactsActiveFiltersPreview: true,
        ContactsList: {
          props: ['contacts'],
          template:
            '<ul><li v-for="contact in contacts" :key="contact.id">{{ contact.name }}</li></ul>',
        },
      },
    },
  });
  await flushPromises();
  return { wrapper, router };
};

describe('ContactsIndex saved segments', () => {
  afterEach(() => vi.restoreAllMocks());

  it('shows a rejected segment without the previous contacts or count and recovers on navigation', async () => {
    vi.spyOn(ContactAPI, 'filter')
      .mockResolvedValueOnce(matchingContacts)
      .mockRejectedValueOnce({ response: { status: 422 } })
      .mockResolvedValueOnce(matchingContacts);
    const { wrapper, router } = await mountSegment(validSegment.id);

    expect(wrapper.text()).toContain('Twelve Contracts');
    expect(wrapper.get('footer').text()).toContain(
      'Showing 1 - 1 of 1 contact'
    );

    await router.push('/contacts/segments/2');
    await flushPromises();

    expect(wrapper.get('[role="alert"]').text()).toBe(
      'This segment has an invalid filter. Edit the segment to fix it.'
    );
    expect(wrapper.text()).not.toContain('Twelve Contracts');
    expect(wrapper.find('footer').exists()).toBe(false);
    expect(
      wrapper.findComponent({ name: 'ContactListHeaderWrapper' }).exists()
    ).toBe(true);

    await router.push('/contacts/segments/1');
    await flushPromises();

    expect(wrapper.find('[role="alert"]').exists()).toBe(false);
    expect(wrapper.text()).toContain('Twelve Contracts');
    expect(wrapper.get('footer').text()).toContain(
      'Showing 1 - 1 of 1 contact'
    );
    wrapper.unmount();
  });

  it('keeps the current results when a previous segment request fails after navigation', async () => {
    const previousRequest = Promise.withResolvers();
    vi.spyOn(ContactAPI, 'filter')
      .mockReturnValueOnce(previousRequest.promise)
      .mockResolvedValueOnce(matchingContacts);
    const { wrapper, router } = await mountSegment(invalidSegment.id);

    await router.push('/contacts/segments/1');
    await flushPromises();

    expect(wrapper.text()).toContain('Twelve Contracts');

    previousRequest.reject({ response: { status: 422 } });
    await flushPromises();

    expect(wrapper.find('[role="alert"]').exists()).toBe(false);
    expect(wrapper.text()).toContain('Twelve Contracts');
    expect(wrapper.get('footer').text()).toContain(
      'Showing 1 - 1 of 1 contact'
    );
    wrapper.unmount();
  });
});
