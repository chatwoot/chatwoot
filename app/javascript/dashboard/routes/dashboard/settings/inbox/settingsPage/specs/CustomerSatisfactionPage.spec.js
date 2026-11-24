import { mount, flushPromises } from '@vue/test-utils';
import { ref } from 'vue';
import CustomerSatisfactionPage from '../CustomerSatisfactionPage.vue';

const { dispatch, alert } = vi.hoisted(() => ({
  dispatch: vi.fn(),
  alert: vi.fn(),
}));

vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch }),
  useMapGetter: () => ref([]),
}));
vi.mock('dashboard/composables', () => ({ useAlert: alert }));
vi.mock('dashboard/composables/useInbox', () => ({
  useInbox: () => ({
    isAWhatsAppChannel: ref(false),
    isATwilioWhatsAppChannel: ref(false),
  }),
}));
vi.mock('dashboard/composables/useCaptain', () => ({
  useCaptain: () => ({ captainEnabled: ref(false) }),
}));

const mountPage = (config = {}) =>
  mount(CustomerSatisfactionPage, {
    props: {
      inbox: { id: 1, csat_survey_enabled: true, csat_config: config },
    },
    global: {
      stubs: {
        NextButton: false,
        Editor: true,
        FluentIcon: true,
        FilterSelect: true,
        CSATDisplayTypeSelector: true,
        ConfirmTemplateUpdateDialog: true,
      },
    },
  });

const responseWindow = wrapper => wrapper.find('#csat-response-window-days');
const saveButton = wrapper => wrapper.find('button[type="submit"]');

describe('CustomerSatisfactionPage', () => {
  beforeEach(() => {
    dispatch.mockResolvedValue({});
  });

  it('defaults existing inboxes to 14 days', () => {
    expect(responseWindow(mountPage()).element.value).toBe('14');
  });

  it('loads the configured response window', () => {
    const wrapper = mountPage({ response_window_days: 3 });
    expect(responseWindow(wrapper).element.value).toBe('3');
  });

  it('saves the response window as a number alongside other CSAT settings', async () => {
    const wrapper = mountPage({ message: 'Please rate us' });
    await responseWindow(wrapper).setValue('1');
    await saveButton(wrapper).trigger('click');
    await flushPromises();

    expect(dispatch).toHaveBeenCalledWith(
      'inboxes/updateInbox',
      expect.objectContaining({
        id: 1,
        csat_config: expect.objectContaining({
          response_window_days: 1,
          message: 'Please rate us',
        }),
      })
    );
  });

  it.each(['', '0', '-1', '1.5'])(
    'prevents saving an invalid response window: %s',
    async value => {
      const wrapper = mountPage();
      await responseWindow(wrapper).setValue(value);
      expect(saveButton(wrapper).attributes('disabled')).toBeDefined();
      expect(wrapper.text()).toContain('INBOX_MGMT.CSAT.RESPONSE_WINDOW.ERROR');
      expect(dispatch).not.toHaveBeenCalledWith(
        'inboxes/updateInbox',
        expect.anything()
      );
    }
  );
});
