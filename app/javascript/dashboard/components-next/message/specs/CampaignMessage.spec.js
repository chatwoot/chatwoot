import { ref } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useCampaignAnalytics } from 'dashboard/composables/useCampaignAnalytics';
import CampaignMessage from '../CampaignMessage.vue';

vi.mock('dashboard/composables/useAdmin');
vi.mock('dashboard/composables/useCampaignAnalytics');
vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: () => ({ accountScopedRoute: name => ({ name }) }),
}));
vi.mock('shared/composables/useExactTimestamp', () => ({
  useExactTimestamp: () => () => 'timestamp',
}));
vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));

describe('campaign title navigation', () => {
  it.each([
    [true, true, true],
    [true, false, false],
    [false, true, false],
  ])('admin=%s analytics=%s link=%s', (admin, analytics, linked) => {
    useAdmin.mockReturnValue({ isAdmin: ref(admin) });
    useCampaignAnalytics.mockReturnValue({ canViewAnalytics: ref(analytics) });
    const wrapper = shallowMount(CampaignMessage, {
      props: {
        recipient: {
          id: 1,
          campaign: { id: 1, title: 'Member offer' },
          sent_at: 100,
          status: 'sent',
          message_content: 'Hello',
        },
      },
      global: { stubs: { RouterLink: { template: '<a><slot /></a>' } } },
    });
    expect(wrapper.find('a').exists()).toBe(linked);
    expect(wrapper.text()).toContain('Member offer');
  });
});
