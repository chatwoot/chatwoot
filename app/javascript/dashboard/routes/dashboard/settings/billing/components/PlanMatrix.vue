<script setup>
import { computed } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import ButtonV4 from 'next/button/Button.vue';

const props = defineProps({
  currentPlan: {
    type: String,
    default: 'basic'
  },
  isTrialActive: {
    type: Boolean,
    default: false
  },
  trialDaysRemaining: {
    type: Number,
    default: 0
  }
});

const emit = defineEmits(['upgrade', 'downgrade', 'cancel']);

const { currentAccount } = useAccount();

const plans = [
  {
    key: 'basic',
    name: 'Basic',
    price: 'Free',
    features: [
      'Up to 2 agents',
      'Basic reporting',
      'Email support',
      'Community access'
    ],
    recommended: false
  },
  {
    key: 'pro',
    name: 'Pro',
    price: '$29/month',
    features: [
      'Up to 10 agents',
      'Advanced reporting',
      'Priority support',
      'Integrations',
      'Custom roles',
      'SLA management'
    ],
    recommended: true
  },
  {
    key: 'premium',
    name: 'Premium',
    price: '$59/month',
    features: [
      'Up to 25 agents',
      'Advanced analytics',
      'API access',
      'White-label branding',
      'Advanced integrations',
      'Audit logs'
    ],
    recommended: false
  },
  {
    key: 'app',
    name: 'App',
    price: '$99/month',
    features: [
      'Unlimited agents',
      'Mobile app access',
      'Advanced automation',
      'Custom workflows',
      'Enterprise integrations',
      'Dedicated support'
    ],
    recommended: false
  },
  {
    key: 'custom',
    name: 'Enterprise',
    price: 'Custom',
    features: [
      'Everything in App',
      'Custom development',
      'On-premise deployment',
      'Dedicated account manager',
      'SLA guarantees',
      'Custom training'
    ],
    recommended: false
  }
];

const currentPlanIndex = computed(() => {
  return plans.findIndex(plan => plan.key === props.currentPlan);
});

const canUpgrade = (planKey) => {
  const planIndex = plans.findIndex(plan => plan.key === planKey);
  return planIndex > currentPlanIndex.value;
};

const canDowngrade = (planKey) => {
  const planIndex = plans.findIndex(plan => plan.key === planKey);
  return planIndex < currentPlanIndex.value && planKey !== 'basic';
};

const isCurrentPlan = (planKey) => {
  return planKey === props.currentPlan;
};

const handlePlanAction = (planKey) => {
  if (canUpgrade(planKey)) {
    emit('upgrade', planKey);
  } else if (canDowngrade(planKey)) {
    emit('downgrade', planKey);
  }
};
</script>

<template>
  <div class="grid lg:grid-cols-3 md:grid-cols-2 grid-cols-1 gap-6">
    <div
      v-for="plan in plans"
      :key="plan.key"
      :class="[
        'relative rounded-lg border p-6 shadow-sm',
        isCurrentPlan(plan.key) 
          ? 'border-blue-500 bg-blue-50 ring-2 ring-blue-500' 
          : 'border-gray-200 bg-white hover:border-gray-300',
        plan.recommended ? 'ring-2 ring-blue-200' : ''
      ]"
    >
      <!-- Recommended badge -->
      <div
        v-if="plan.recommended"
        class="absolute -top-3 left-1/2 transform -translate-x-1/2"
      >
        <span class="bg-blue-500 text-white px-3 py-1 text-sm font-medium rounded-full">
          Recommended
        </span>
      </div>

      <!-- Current plan badge -->
      <div
        v-if="isCurrentPlan(plan.key)"
        class="absolute -top-3 right-4"
      >
        <span class="bg-green-500 text-white px-3 py-1 text-sm font-medium rounded-full">
          Current Plan
        </span>
      </div>

      <!-- Trial badge -->
      <div
        v-if="isCurrentPlan(plan.key) && isTrialActive"
        class="absolute -top-3 left-4"
      >
        <span class="bg-orange-500 text-white px-3 py-1 text-sm font-medium rounded-full">
          {{ trialDaysRemaining }} days trial
        </span>
      </div>

      <!-- Plan header -->
      <div class="mb-4">
        <h3 class="text-xl font-semibold text-gray-900">{{ plan.name }}</h3>
        <p class="text-2xl font-bold text-gray-900 mt-2">{{ plan.price }}</p>
        <p v-if="plan.price !== 'Free' && plan.price !== 'Custom'" class="text-sm text-gray-500">
          per month, billed monthly
        </p>
      </div>

      <!-- Features list -->
      <ul class="mb-6 space-y-2">
        <li
          v-for="feature in plan.features"
          :key="feature"
          class="flex items-start"
        >
          <svg class="h-5 w-5 text-green-500 mr-3 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
          </svg>
          <span class="text-sm text-gray-600">{{ feature }}</span>
        </li>
      </ul>

      <!-- Action button -->
      <div class="mt-auto">
        <ButtonV4
          v-if="isCurrentPlan(plan.key)"
          block
          solid
          slate
          disabled
        >
          Current Plan
        </ButtonV4>
        <ButtonV4
          v-else-if="canUpgrade(plan.key)"
          block
          solid
          blue
          @click="handlePlanAction(plan.key)"
        >
          Upgrade to {{ plan.name }}
        </ButtonV4>
        <ButtonV4
          v-else-if="canDowngrade(plan.key)"
          block
          outline
          slate
          @click="handlePlanAction(plan.key)"
        >
          Downgrade to {{ plan.name }}
        </ButtonV4>
        <ButtonV4
          v-else-if="plan.key === 'custom'"
          block
          outline
          blue
          @click="$emit('contact-sales')"
        >
          Contact Sales
        </ButtonV4>
      </div>
    </div>
  </div>

  <!-- Cancel subscription option -->
  <div v-if="currentPlan !== 'basic'" class="mt-8 p-4 bg-red-50 border border-red-200 rounded-lg">
    <h4 class="text-lg font-medium text-red-800 mb-2">Cancel Subscription</h4>
    <p class="text-sm text-red-600 mb-4">
      You can cancel your subscription at any time. Your plan will remain active until the end of your billing period.
    </p>
    <ButtonV4
      outline
      red
      @click="$emit('cancel')"
    >
      Cancel Subscription
    </ButtonV4>
  </div>
</template>