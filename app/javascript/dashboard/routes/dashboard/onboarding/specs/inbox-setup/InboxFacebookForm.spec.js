import { flushPromises, mount } from '@vue/test-utils';
import { ref, nextTick } from 'vue';
import InboxFacebookForm from '../../inbox-setup/InboxFacebookForm.vue';
import { useFacebookPageConnect } from 'dashboard/composables/useFacebookPageConnect';

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));
vi.mock('dashboard/store/utils/api', () => ({
  parseAPIErrorResponse: vi.fn(),
}));
vi.mock('dashboard/composables/useFacebookPageConnect', () => ({
  useFacebookPageConnect: vi.fn(),
}));

const { dispatch } = vi.hoisted(() => ({ dispatch: vi.fn() }));
vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch }),
}));

const NextButtonStub = {
  props: ['label', 'disabled', 'isLoading'],
  emits: ['click'],
  template: `<button :disabled="disabled" @click="$emit('click')">{{ label }}</button>`,
};
const ComboBoxStub = {
  props: ['modelValue', 'options'],
  emits: ['update:modelValue'],
  template: '<div data-test="combobox" />',
};

const PAGES = [
  { id: 'p1', name: 'Page One', access_token: 'pt1' },
  { id: 'p2', name: 'Page Two', access_token: 'pt2', exists: true },
];

const LAUNCH = 'ONBOARDING_INBOX_SETUP.CHANNELS_DIALOG.FACEBOOK_LAUNCH';
const CONNECT = 'ONBOARDING_INBOX_SETUP.CHANNELS_DIALOG.CONNECT';

let loginAndFetchPages;
let preloadSdk;

const mountForm = () =>
  mount(InboxFacebookForm, {
    global: {
      stubs: {
        NextButton: NextButtonStub,
        ComboBox: ComboBoxStub,
        Spinner: true,
      },
    },
  });

const clickButton = (wrapper, label) =>
  wrapper
    .findAll('button')
    .find(button => button.text() === label)
    .trigger('click');

beforeEach(() => {
  vi.clearAllMocks();
  preloadSdk = vi.fn();
  loginAndFetchPages = vi.fn();
  useFacebookPageConnect.mockReturnValue({
    isAuthenticating: ref(false),
    preloadSdk,
    loginAndFetchPages,
  });
  dispatch.mockResolvedValue({ id: 1 });
});

describe('InboxFacebookForm', () => {
  it('preloads the SDK on mount', () => {
    mountForm();
    expect(preloadSdk).toHaveBeenCalled();
  });

  it('lists only connectable pages and creates an inbox for the selected one', async () => {
    loginAndFetchPages.mockResolvedValue({
      userAccessToken: 'tok',
      pages: PAGES,
    });
    const wrapper = mountForm();

    await clickButton(wrapper, LAUNCH);
    await flushPromises();
    await nextTick();

    // p2 is already connected (exists), so only p1 is offered.
    const combobox = wrapper.findComponent(ComboBoxStub);
    expect(combobox.props('options')).toEqual([
      { value: 'p1', label: 'Page One' },
    ]);

    combobox.vm.$emit('update:modelValue', 'p1');
    await nextTick();

    await clickButton(wrapper, CONNECT);
    await flushPromises();

    expect(dispatch).toHaveBeenCalledWith('inboxes/createFBChannel', {
      user_access_token: 'tok',
      page_access_token: 'pt1',
      page_id: 'p1',
      inbox_name: 'Page One',
    });
    expect(wrapper.emitted('created')).toBeTruthy();
  });

  it('shows the empty state when every page is already connected', async () => {
    loginAndFetchPages.mockResolvedValue({
      userAccessToken: 'tok',
      pages: [
        { id: 'p2', name: 'Page Two', access_token: 'pt2', exists: true },
      ],
    });
    const wrapper = mountForm();

    await clickButton(wrapper, LAUNCH);
    await flushPromises();
    await nextTick();

    expect(wrapper.text()).toContain(
      'ONBOARDING_INBOX_SETUP.CHANNELS_DIALOG.FACEBOOK_NO_PAGES'
    );
    expect(wrapper.find('[data-test="combobox"]').exists()).toBe(false);
  });

  it('shows an error when the connection fails', async () => {
    loginAndFetchPages.mockRejectedValue(new Error('boom'));
    const wrapper = mountForm();

    await clickButton(wrapper, LAUNCH);
    await flushPromises();
    await nextTick();

    expect(wrapper.text()).toContain(
      'ONBOARDING_INBOX_SETUP.CHANNELS_DIALOG.FACEBOOK_ERROR'
    );
    expect(dispatch).not.toHaveBeenCalled();
  });

  it('stays on the connect prompt without an error when cancelled', async () => {
    loginAndFetchPages.mockResolvedValue(null);
    const wrapper = mountForm();

    await clickButton(wrapper, LAUNCH);
    await flushPromises();
    await nextTick();

    expect(wrapper.text()).not.toContain(
      'ONBOARDING_INBOX_SETUP.CHANNELS_DIALOG.FACEBOOK_ERROR'
    );
    // Launch button is still available to retry.
    expect(
      wrapper.findAll('button').some(button => button.text() === LAUNCH)
    ).toBe(true);
  });
});
