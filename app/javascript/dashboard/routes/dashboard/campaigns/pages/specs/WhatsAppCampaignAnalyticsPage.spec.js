import { ref } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';
import { useRouter } from 'vue-router';
import Page from '../WhatsAppCampaignAnalyticsPage.vue';

vi.mock('dashboard/composables/useAccount');
vi.mock('dashboard/composables/usePolicy');
vi.mock('dashboard/composables/store');
vi.mock('vue-router', () => ({ useRouter: vi.fn() }));
vi.mock('../WhatsAppCampaignAnalyticsContent.vue', () => ({
  default: { template: '<div>Analytics</div>' },
}));

describe('campaign analytics paywall', () => {
  let showPaywall;
  let push;
  beforeEach(() => {
    showPaywall = ref(true);
    usePolicy.mockReturnValue({
      shouldShowPaywall: () => showPaywall.value,
    });
    push = vi.fn();
    useRouter.mockReturnValue({ push });
    useAccount.mockReturnValue({
      isOnChatwootCloud: ref(true),
      accountScopedRoute: name => ({ name, params: { accountId: 1 } }),
    });
    useMapGetter.mockReturnValue(ref({ type: 'User' }));
  });

  it('shows billing instead of mounting analytics for a free account', () => {
    const wrapper = shallowMount(Page);
    expect(
      wrapper
        .findComponent({ name: 'WhatsAppCampaignAnalyticsContent' })
        .exists()
    ).toBe(false);
    const paywall = wrapper.findComponent({ name: 'BasePaywallModal' });
    expect(paywall.props('isOnChatwootCloud')).toBe(true);
    paywall.vm.$emit('upgrade');
    expect(push).toHaveBeenCalledWith({
      name: 'billing_settings_index',
      params: { accountId: 1 },
    });
  });

  it('mounts analytics only when the plan allows access and removes it on downgrade', async () => {
    showPaywall.value = false;
    const wrapper = shallowMount(Page);
    expect(wrapper.findComponent({ name: 'BasePaywallModal' }).exists()).toBe(
      false
    );
    expect(
      wrapper
        .findComponent({ name: 'WhatsAppCampaignAnalyticsContent' })
        .exists()
    ).toBe(true);
    showPaywall.value = true;
    await wrapper.vm.$nextTick();
    expect(
      wrapper
        .findComponent({ name: 'WhatsAppCampaignAnalyticsContent' })
        .exists()
    ).toBe(false);
    expect(wrapper.findComponent({ name: 'BasePaywallModal' }).exists()).toBe(
      true
    );
  });
});
