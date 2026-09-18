import { reactive, ref } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { useConfig } from 'dashboard/composables/useConfig';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';
import { useRoute, useRouter } from 'vue-router';
import Page from '../WhatsAppCampaignAnalyticsPage.vue';

vi.mock('dashboard/composables/useAccount');
vi.mock('dashboard/composables/usePolicy');
vi.mock('dashboard/composables/useConfig');
vi.mock('dashboard/composables/store');
vi.mock('vue-router', () => ({ useRouter: vi.fn(), useRoute: vi.fn() }));
vi.mock('../WhatsAppCampaignAnalyticsContent.vue', () => ({
  default: { template: '<div>Analytics</div>' },
}));

describe('campaign analytics paywall', () => {
  let showPaywall;
  let featureEnabled;
  let currentAccount;
  let route;
  let push;
  let replace;
  beforeEach(() => {
    showPaywall = ref(true);
    featureEnabled = ref(true);
    currentAccount = ref({ id: 1 });
    route = reactive({ name: 'campaigns_whatsapp_analytics' });
    useRoute.mockReturnValue(route);
    useConfig.mockReturnValue({ isEnterprise: true });
    usePolicy.mockReturnValue({
      shouldShowPaywall: () => showPaywall.value,
      isFeatureFlagEnabled: () => featureEnabled.value,
    });
    push = vi.fn();
    replace = vi.fn();
    useRouter.mockReturnValue({ push, replace });
    useAccount.mockReturnValue({
      isOnChatwootCloud: ref(true),
      currentAccount,
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
  it('does not mount analytics for a branded account whose feature is disabled', () => {
    showPaywall.value = false;
    featureEnabled.value = false;
    const wrapper = shallowMount(Page);
    expect(replace).toHaveBeenCalledWith({
      name: 'campaigns_whatsapp_index',
      params: { accountId: 1 },
    });
    expect(
      wrapper
        .findComponent({ name: 'WhatsAppCampaignAnalyticsContent' })
        .exists()
    ).toBe(false);
    expect(wrapper.findComponent({ name: 'BasePaywallModal' }).exists()).toBe(
      false
    );
  });

  it('does not mount Enterprise analytics on Community', () => {
    showPaywall.value = false;
    useConfig.mockReturnValue({ isEnterprise: false });
    const wrapper = shallowMount(Page);
    expect(
      wrapper
        .findComponent({ name: 'WhatsAppCampaignAnalyticsContent' })
        .exists()
    ).toBe(false);
  });
  it.each([true, false])(
    'waits for account features before redirecting, eligible=%s',
    async eligible => {
      currentAccount.value = {};
      featureEnabled.value = false;
      showPaywall.value = false;
      const wrapper = shallowMount(Page);
      expect(replace).not.toHaveBeenCalled();

      featureEnabled.value = eligible;
      currentAccount.value = { id: 1 };
      await wrapper.vm.$nextTick();
      expect(
        wrapper
          .findComponent({ name: 'WhatsAppCampaignAnalyticsContent' })
          .exists()
      ).toBe(eligible);
      expect(replace).toHaveBeenCalledTimes(eligible ? 0 : 1);
    }
  );
  it('does not redirect another campaign page from its cached watcher', async () => {
    showPaywall.value = false;
    const wrapper = shallowMount(Page);
    route.name = 'campaigns_whatsapp_new';
    featureEnabled.value = false;
    await wrapper.vm.$nextTick();
    expect(replace).not.toHaveBeenCalled();
    route.name = 'campaigns_whatsapp_analytics';
    await wrapper.vm.$nextTick();
    expect(replace).toHaveBeenCalledTimes(1);
  });
});
