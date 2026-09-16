import { flushPromises, mount } from '@vue/test-utils';
import HelpCenterCreationStatus from '../../inbox-setup/HelpCenterCreationStatus.vue';
import OnboardingAPI from 'dashboard/api/onboarding';

vi.mock('dashboard/api/onboarding', () => ({
  default: {
    getHelpCenterGeneration: vi.fn(),
  },
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: (key, params = {}) => {
      if (key.endsWith('HELP_CENTER_CATEGORIES')) {
        return `${params.count} categories`;
      }
      if (key.endsWith('HELP_CENTER_SUMMARY')) {
        return `${params.count} articles across ${params.categories}`;
      }
      if (key.endsWith('HELP_CENTER_ARTICLES')) {
        return `${params.count} articles`;
      }
      return key;
    },
  }),
}));

const mountStatus = () =>
  mount(HelpCenterCreationStatus, {
    global: {
      stubs: {
        CreationStatusRow: {
          props: ['ready', 'title', 'description', 'status'],
          template:
            '<div data-test="row" :data-ready="ready">{{ status }}</div>',
        },
      },
    },
  });

describe('HelpCenterCreationStatus', () => {
  afterEach(() => {
    vi.useRealTimers();
    vi.clearAllMocks();
  });

  it('renders completed summary from the status endpoint', async () => {
    OnboardingAPI.getHelpCenterGeneration.mockResolvedValue({
      data: {
        generation_id: 'generation-123',
        state: { status: 'completed' },
        articles_count: 3,
        categories_count: 2,
      },
    });

    const wrapper = mountStatus();
    await flushPromises();

    expect(wrapper.find('[data-test="row"]').attributes('data-ready')).toBe(
      'true'
    );
    expect(wrapper.find('[data-test="row"]').text()).toBe(
      '3 articles across 2 categories'
    );
  });

  it('hides the row when generation is skipped', async () => {
    OnboardingAPI.getHelpCenterGeneration.mockResolvedValue({
      data: {
        generation_id: 'generation-123',
        state: { status: 'skipped' },
      },
    });

    const wrapper = mountStatus();
    await flushPromises();

    expect(wrapper.find('[data-test="row"]').exists()).toBe(false);
  });

  it('polls while generating and stops after completion', async () => {
    vi.useFakeTimers();
    OnboardingAPI.getHelpCenterGeneration
      .mockResolvedValueOnce({
        data: {
          generation_id: 'generation-123',
          state: { status: 'generating' },
          articles_count: 1,
          categories_count: 0,
        },
      })
      .mockResolvedValueOnce({
        data: {
          generation_id: 'generation-123',
          state: { status: 'completed' },
          articles_count: 2,
          categories_count: 1,
        },
      });

    const wrapper = mountStatus();
    await flushPromises();

    expect(wrapper.find('[data-test="row"]').text()).toBe('1 articles');

    vi.advanceTimersByTime(5000);
    await flushPromises();

    expect(OnboardingAPI.getHelpCenterGeneration).toHaveBeenCalledTimes(2);
    expect(wrapper.find('[data-test="row"]').attributes('data-ready')).toBe(
      'true'
    );
    expect(wrapper.find('[data-test="row"]').text()).toBe(
      '2 articles across 1 categories'
    );

    vi.advanceTimersByTime(5000);
    await flushPromises();

    expect(OnboardingAPI.getHelpCenterGeneration).toHaveBeenCalledTimes(2);
  });
});
