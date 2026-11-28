import { shallowMount } from '@vue/test-utils';
import ComposeConversation from '../ComposeConversation.vue';
import Popover from 'dashboard/components-next/popover/Popover.vue';

const { dispatch, getterValues } = vi.hoisted(() => ({
  dispatch: vi.fn(),
  getterValues: {
    'contacts/getContactById': { value: id => ({ id: Number(id) }) },
    'inboxes/getInboxes': { value: [] },
  },
}));

vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch }),
  useMapGetter: key => getterValues[key],
}));

vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));

vi.mock('dashboard/composables/useUISettings', () => ({
  useUISettings: () => ({ fetchSignatureFlagFromUISettings: vi.fn() }),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

describe('ComposeConversation', () => {
  beforeEach(() => {
    dispatch.mockClear();
  });

  it('fetches the contactable inboxes of the contact when the popover opens', () => {
    const wrapper = shallowMount(ComposeConversation, {
      props: { contactId: '48213' },
    });

    wrapper.findComponent(Popover).vm.$emit('show');

    expect(dispatch).toHaveBeenCalledWith(
      'contacts/fetchContactableInbox',
      '48213'
    );
  });

  it('does not fetch contactable inboxes when no contact is preselected', () => {
    const wrapper = shallowMount(ComposeConversation);

    wrapper.findComponent(Popover).vm.$emit('show');

    expect(dispatch).toHaveBeenCalledWith('inboxes/get');
    expect(dispatch).not.toHaveBeenCalledWith(
      'contacts/fetchContactableInbox',
      expect.anything()
    );
  });
});
