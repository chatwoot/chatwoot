import { shallowMount } from '@vue/test-utils';
import PlanSelector from '../PlanSelector.vue';

const plans = [
  {
    key: 'pro_monthly',
    name: 'Pro',
    tier: 'pro',
    interval: 'month',
    amount_kd: 75,
    limits: { ai_responses_per_month: 25000, knowledge_base_documents: 100 },
    features: { crm_integration: true, api_access: true },
  },
  {
    key: 'pro_annual',
    name: 'Pro',
    tier: 'pro',
    interval: 'year',
    amount_kd: 900,
    limits: { ai_responses_per_month: 25000, knowledge_base_documents: 100 },
    features: { crm_integration: true, api_access: true },
  },
  {
    key: 'basic_monthly',
    name: 'Basic',
    tier: 'basic',
    interval: 'month',
    amount_kd: 60,
    limits: { ai_responses_per_month: 10000, knowledge_base_documents: 50 },
    features: {},
  },
  {
    key: 'basic_annual',
    name: 'Basic',
    tier: 'basic',
    interval: 'year',
    amount_kd: 600,
    limits: { ai_responses_per_month: 10000, knowledge_base_documents: 50 },
    features: {},
  },
];

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

const globalConfig = {
  global: {
    mocks: {
      $t: key => key,
    },
    stubs: {
      ButtonV4: { template: '<button><slot /></button>' },
    },
  },
};

describe('PlanSelector.vue', () => {
  describe('current tier badge across billing intervals', () => {
    it('shows current badge for same-tier plan on different interval', () => {
      // User is on pro_monthly, viewing annual plans — pro_annual should show "Current" badge
      const wrapper = shallowMount(PlanSelector, {
        props: {
          plans,
          currentPlan: { key: 'pro_monthly', tier: 'pro' },
          isCheckingOut: false,
        },
        ...globalConfig,
      });

      // Switch to annual view
      const annualButton = wrapper.findAll('button').at(1);
      annualButton.trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        const cards = wrapper.findAll('.rounded-xl');
        const proAnnualCard = cards.find(c => c.text().includes('Pro'));
        expect(proAnnualCard.classes()).toContain('border-n-brand');
        expect(proAnnualCard.text()).toContain(
          'BILLING_SETTINGS.PLAN_SELECTOR.CURRENT'
        );
      });
    });

    it('hides subscribe button only for exact current plan', () => {
      const wrapper = shallowMount(PlanSelector, {
        props: {
          plans,
          currentPlan: { key: 'pro_monthly', tier: 'pro' },
          isCheckingOut: false,
        },
        ...globalConfig,
      });

      // On monthly view, pro_monthly should NOT show subscribe button
      const cards = wrapper.findAll('.rounded-xl');
      const proCard = cards.find(c => c.text().includes('Pro'));
      expect(proCard.findComponent({ name: 'ButtonV4' }).exists()).toBe(false);

      // Basic card SHOULD show subscribe button
      const basicCard = cards.find(c => c.text().includes('Basic'));
      expect(basicCard.find('button').exists()).toBe(true);
    });

    it('shows subscribe button for same-tier plan on different interval', async () => {
      const wrapper = shallowMount(PlanSelector, {
        props: {
          plans,
          currentPlan: { key: 'pro_monthly', tier: 'pro' },
          isCheckingOut: false,
        },
        ...globalConfig,
      });

      // Switch to annual view
      const annualButton = wrapper.findAll('button').at(1);
      await annualButton.trigger('click');

      // pro_annual has same tier but different key — subscribe button should show
      const cards = wrapper.findAll('.rounded-xl');
      const proAnnualCard = cards.find(c => c.text().includes('Pro'));
      expect(proAnnualCard.find('button').exists()).toBe(true);
    });
  });

  describe('plan selection', () => {
    it('emits select event with plan key on button click', async () => {
      const wrapper = shallowMount(PlanSelector, {
        props: {
          plans,
          currentPlan: { key: 'pro_monthly', tier: 'pro' },
          isCheckingOut: false,
        },
        ...globalConfig,
      });

      const basicCard = wrapper
        .findAll('.rounded-xl')
        .find(c => c.text().includes('Basic'));
      await basicCard.find('button').trigger('click');

      expect(wrapper.emitted('select')).toBeTruthy();
      expect(wrapper.emitted('select')[0]).toEqual(['basic_monthly']);
    });
  });
});
