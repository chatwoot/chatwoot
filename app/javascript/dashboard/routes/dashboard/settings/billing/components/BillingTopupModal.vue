<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';

import ButtonV4 from 'next/button/Button.vue';

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false,
  },
  options: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update:modelValue', 'confirm']);
const { t } = useI18n();
const selectedCredits = ref(null);

watch(
  () => props.modelValue,
  value => {
    if (!value) {
      selectedCredits.value = null;
    }
  }
);

watch(
  () => props.options,
  options => {
    if (
      props.modelValue &&
      (!selectedCredits.value ||
        !options?.some(opt => opt.credits === selectedCredits.value))
    ) {
      selectedCredits.value = options?.[0]?.credits || null;
    }
  },
  { immediate: true }
);

const formattedOptions = computed(() => {
  return (props.options || []).map(option => ({
    ...option,
    label: `${option.credits.toLocaleString()} ${t(
      'BILLING_SETTINGS.V2_BILLING.TOPUP.CREDITS_LABEL'
    )}`,
    price: new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency: (option.currency || 'usd').toUpperCase(),
      minimumFractionDigits: 2,
    }).format(option.amount),
  }));
});

const onClose = () => {
  emit('update:modelValue', false);
};

const onConfirm = () => {
  if (!selectedCredits.value) return;
  emit('confirm', selectedCredits.value);
};
</script>

<template>
  <teleport to="body">
    <transition name="fade">
      <div
        v-if="modelValue"
        class="fixed inset-0 z-50 flex items-center justify-center bg-n-alpha-7 p-4"
        role="dialog"
        aria-modal="true"
      >
        <div class="w-full max-w-lg rounded-2xl bg-n-solid-1 shadow-xl">
          <header class="px-6 pt-6 pb-4 border-b border-n-weak">
            <h3 class="text-lg font-semibold text-n-slate-12">
              {{ $t('BILLING_SETTINGS.V2_BILLING.TOPUP.TITLE') }}
            </h3>
            <p class="mt-1 text-sm text-n-slate-11">
              {{ $t('BILLING_SETTINGS.V2_BILLING.TOPUP.DESCRIPTION') }}
            </p>
          </header>

          <section class="px-6 py-4 space-y-4">
            <div class="grid gap-3">
              <label
                v-for="option in formattedOptions"
                :key="option.credits"
                class="flex cursor-pointer items-center justify-between rounded-xl border px-4 py-3 transition-colors"
                :class="
                  selectedCredits === option.credits
                    ? 'border-n-brand bg-n-brand/5'
                    : 'border-n-weak hover:border-n-brand/60'
                "
              >
                <div>
                  <p class="text-sm font-medium text-n-slate-12">
                    {{ option.label }}
                  </p>
                  <p class="text-xs text-n-slate-10">
                    {{
                      $t('BILLING_SETTINGS.V2_BILLING.TOPUP.INCLUDES', {
                        amount: option.price,
                      })
                    }}
                  </p>
                </div>
                <input
                  v-model="selectedCredits"
                  type="radio"
                  class="form-radio h-4 w-4 text-n-brand"
                  :value="option.credits"
                />
              </label>
            </div>
          </section>

          <footer
            class="flex items-center justify-end gap-3 border-t border-n-weak px-6 py-4"
          >
            <ButtonV4 sm faded slate @click="onClose">
              {{ $t('BILLING_SETTINGS.V2_BILLING.TOPUP.CANCEL') }}
            </ButtonV4>
            <ButtonV4
              sm
              solid
              blue
              :disabled="!selectedCredits"
              :is-loading="isLoading"
              @click="onConfirm"
            >
              {{ $t('BILLING_SETTINGS.V2_BILLING.TOPUP.CONFIRM') }}
            </ButtonV4>
          </footer>
        </div>
      </div>
    </transition>
  </teleport>
</template>
