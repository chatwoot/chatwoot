import { ref } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { useCampaignAnalytics } from 'dashboard/composables/useCampaignAnalytics';
import CampaignList from '../CampaignList.vue';
import CampaignCard from 'dashboard/components-next/Campaigns/CampaignCard/CampaignCard.vue';

vi.mock('dashboard/composables/useCampaignAnalytics');
vi.mock('dashboard/composables/useConfig', () => ({
  useConfig: () => ({ isEnterprise: true }),
}));
vi.mock(
  'dashboard/components-next/Campaigns/CampaignCard/CampaignCard.vue',
  () => ({ default: { props: ['showAnalytics'], template: '<div />' } })
);

describe('campaign analytics action', () => {
  it.each([
    [true, false, true],
    [false, true, true],
    [false, false, false],
  ])('eligible=%s paywall=%s visible=%s', (eligible, paywall, visible) => {
    useCampaignAnalytics.mockReturnValue({
      canViewAnalytics: ref(eligible),
      showPaywall: ref(paywall),
    });
    const wrapper = shallowMount(CampaignList, {
      props: {
        campaigns: [
          {
            id: 1,
            campaign_status: 'completed',
            inbox: { channel_type: 'Channel::Whatsapp' },
          },
        ],
      },
    });
    expect(wrapper.findComponent(CampaignCard).props('showAnalytics')).toBe(
      visible
    );
  });
});
