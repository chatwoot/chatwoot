<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  plan: {
    type: Object,
    required: true,
  },
  isSelected: {
    type: Boolean,
    default: false,
  },
  isCurrent: {
    type: Boolean,
    default: false,
  },
  isDisabled: {
    type: Boolean,
    default: false,
  },
});

defineEmits(['select']);

const { t } = useI18n();

const displayPrice = computed(() => {
  const licenseFee = props.plan.components?.find(c => c.type === 'license_fee');
  const amount = licenseFee?.unit_amount || 0;
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
});

const monthlyCredits = computed(() => {
  const serviceAction = props.plan.components?.find(
    c => c.type === 'service_action'
  );
  return serviceAction?.credit_amount || 0;
});

const cardClasses = computed(() => {
  const baseClasses = 'relative flex flex-col gap-2 p-4 transition-all border rounded-xl';

  if (props.isDisabled) {
    if (props.isSelected) {
      return `${baseClasses} border-n-teal-9 bg-n-teal-9/5 opacity-70 cursor-not-allowed`;
    }
    return `${baseClasses} border-n-weak opacity-50 cursor-not-allowed`;
  }

  if (props.isSelected) {
    return `${baseClasses} border-n-teal-9 bg-n-teal-9/5 cursor-pointer`;
  }
  return `${baseClasses} border-n-weak hover:border-n-strong cursor-pointer`;
});

const handleClick = () => {
  if (!props.isDisabled) {
    // Emit is handled in template
  }
};
</script>

<template>
  <div :class="cardClasses" @click="!isDisabled && $emit('select', plan)">
    <div
      v-if="isCurrent"
      class="absolute px-2 py-1 text-xs font-medium rounded -top-3 left-3 bg-n-solid-3 text-n-slate-11"
    >
      {{ t('BILLING_SETTINGS.CHANGE_PLAN_MODAL.CURRENT_PLAN') }}
    </div>
    <div
      v-if="isSelected"
      class="absolute flex items-center justify-center rounded-full -top-2 -right-2 size-6 bg-n-teal-9"
    >
      <span class="text-white i-lucide-check size-4" />
    </div>
    <h3 class="text-lg font-medium text-n-slate-12">
      {{ plan.display_name }}
    </h3>
    <div class="flex items-baseline gap-1">
      <span class="text-2xl font-semibold text-n-slate-12">
        {{ displayPrice }}
      </span>
      <span class="text-sm text-n-slate-11">
        {{ t('BILLING_SETTINGS.CHANGE_PLAN_MODAL.PER_USER_MONTH') }}
      </span>
    </div>
    <div class="text-sm text-n-slate-11">
      {{ monthlyCredits }}
      {{ t('BILLING_SETTINGS.CHANGE_PLAN_MODAL.AI_CREDITS_MONTH') }}
    </div>
  </div>
</template>
