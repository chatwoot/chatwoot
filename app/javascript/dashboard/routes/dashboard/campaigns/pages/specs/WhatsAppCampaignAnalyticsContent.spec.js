import { ref } from 'vue';
import { flushPromises, mount } from '@vue/test-utils';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import CampaignsAPI from 'dashboard/api/campaigns';
import Content from '../WhatsAppCampaignAnalyticsContent.vue';

vi.mock('dashboard/composables/store');
vi.mock('vue-router', () => ({ useRouter: vi.fn(), useRoute: vi.fn() }));
vi.mock('dashboard/api/campaigns', () => ({
  default: { analyticsMetrics: vi.fn(), analyticsContacts: vi.fn() },
}));

describe('campaign analytics completion', () => {
  let campaigns;
  let dispatch;
  let wrapper;
  const partialMetrics = { audience: 100, skipped: 100 };
  const finalMetrics = { audience: 150, skipped: 150 };
  const partialContacts = {
    payload: [{ contact: { id: 100 }, status: 'skipped' }],
    meta: { total_count: 100 },
  };
  const finalContacts = {
    payload: [{ contact: { id: 150 }, status: 'skipped' }],
    meta: { total_count: 150 },
  };

  beforeEach(() => {
    vi.useFakeTimers();
    campaigns = ref([{ id: 1, campaign_status: 'processing' }]);
    dispatch = vi.fn();
    useMapGetter.mockReturnValue(campaigns);
    useStore.mockReturnValue({ dispatch });
    useRoute.mockReturnValue({ params: { campaignId: '1' } });
    useRouter.mockReturnValue({ push: vi.fn() });
    CampaignsAPI.analyticsMetrics.mockResolvedValue({ data: partialMetrics });
    CampaignsAPI.analyticsContacts.mockResolvedValue({ data: partialContacts });

    wrapper = mount(
      {
        components: { Content },
        template: '<KeepAlive><Content /></KeepAlive>',
      },
      {
        shallow: true,
        global: {
          renderStubDefaultSlot: true,
          stubs: {
            WhatsAppCampaignAnalyticsContent: false,
            KeepAlive: false,
            CampaignDeliveryTable: {
              name: 'CampaignDeliveryTable',
              props: ['deliveries', 'loading', 'noDataMessage'],
              template:
                '<div><slot name="filters" /><slot name="footer" /></div>',
            },
          },
        },
      }
    );
  });

  afterEach(() => {
    wrapper.unmount();
    vi.useRealTimers();
  });

  it.each([true, false])(
    'refreshes final results when partial responses arrive before completion: %s',
    async partialResponsesArriveFirst => {
      await flushPromises();
      expect(
        wrapper
          .findAllComponents({ name: 'CampaignMetricCard' })[0]
          .props('value')
      ).toBe(100);

      let resolveMetrics;
      let resolveContacts;
      let resolveCampaigns;
      CampaignsAPI.analyticsMetrics
        .mockResolvedValue({ data: finalMetrics })
        .mockImplementationOnce(
          () =>
            new Promise(resolve => {
              resolveMetrics = resolve;
            })
        );
      CampaignsAPI.analyticsContacts
        .mockResolvedValue({ data: finalContacts })
        .mockImplementationOnce(
          () =>
            new Promise(resolve => {
              resolveContacts = resolve;
            })
        );
      dispatch.mockImplementationOnce(
        () =>
          new Promise(resolve => {
            resolveCampaigns = resolve;
          })
      );

      await vi.advanceTimersByTimeAsync(5000);
      expect(dispatch).toHaveBeenCalledWith('campaigns/get');
      if (partialResponsesArriveFirst) {
        resolveMetrics({ data: partialMetrics });
        resolveContacts({ data: partialContacts });
        await flushPromises();
      }

      campaigns.value[0].campaign_status = 'completed';
      resolveCampaigns();
      await flushPromises();

      expect(CampaignsAPI.analyticsMetrics).toHaveBeenCalledTimes(3);
      expect(CampaignsAPI.analyticsContacts).toHaveBeenCalledTimes(3);
      expect(
        wrapper
          .findAllComponents({ name: 'CampaignMetricCard' })[0]
          .props('value')
      ).toBe(150);
      expect(wrapper.findComponent({ name: 'Banner' }).exists()).toBe(false);

      if (!partialResponsesArriveFirst) {
        resolveMetrics({ data: partialMetrics });
        resolveContacts({ data: partialContacts });
        await flushPromises();
      }

      expect(
        wrapper
          .findAllComponents({ name: 'CampaignMetricCard' })[0]
          .props('value')
      ).toBe(150);
      expect(
        wrapper
          .findComponent({ name: 'CampaignDeliveryTable' })
          .props('deliveries')
      ).toEqual(finalContacts.payload);
      expect(
        wrapper.findComponent({ name: 'PaginationFooter' }).props('totalItems')
      ).toBe(150);

      await vi.advanceTimersByTimeAsync(10000);
      expect(CampaignsAPI.analyticsMetrics).toHaveBeenCalledTimes(3);
      expect(CampaignsAPI.analyticsContacts).toHaveBeenCalledTimes(3);
      expect(dispatch).toHaveBeenCalledTimes(1);
    }
  );
});
