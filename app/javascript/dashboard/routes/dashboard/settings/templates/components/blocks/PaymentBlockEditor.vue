<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  properties: {
    type: Object,
    required: true,
  },
  parameters: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['update:properties']);

const { t } = useI18n();

const localProps = ref({ ...props.properties });

watch(
  localProps,
  newValue => {
    emit('update:properties', newValue);
  },
  { deep: true }
);
</script>

<template>
  <div class="space-y-4">
    <!-- Merchant Name -->
    <div>
      <label class="block text-sm font-medium text-n-slate-12 mb-2">
        {{ t('TEMPLATES.BUILDER.PAYMENT_BLOCK.MERCHANT_NAME.LABEL') }}
      </label>
      <input
        v-model="localProps.merchantName"
        type="text"
        :placeholder="
          t('TEMPLATES.BUILDER.PAYMENT_BLOCK.MERCHANT_NAME.PLACEHOLDER')
        "
        class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7 font-mono"
      />
    </div>

    <!-- Amount and Currency -->
    <div class="grid grid-cols-2 gap-4">
      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('TEMPLATES.BUILDER.PAYMENT_BLOCK.AMOUNT.LABEL') }}
        </label>
        <input
          v-model="localProps.amount"
          type="text"
          :placeholder="t('TEMPLATES.BUILDER.PAYMENT_BLOCK.AMOUNT.PLACEHOLDER')"
          class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7 font-mono"
        />
      </div>

      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('TEMPLATES.BUILDER.PAYMENT_BLOCK.CURRENCY.LABEL') }}
        </label>
        <input
          v-model="localProps.currency"
          type="text"
          :placeholder="
            t('TEMPLATES.BUILDER.PAYMENT_BLOCK.CURRENCY.PLACEHOLDER')
          "
          class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
        />
      </div>
    </div>

    <!-- Description -->
    <div>
      <label class="block text-sm font-medium text-n-slate-12 mb-2">
        {{ t('TEMPLATES.BUILDER.PAYMENT_BLOCK.DESCRIPTION.LABEL') }}
      </label>
      <textarea
        v-model="localProps.description"
        rows="3"
        :placeholder="
          t('TEMPLATES.BUILDER.PAYMENT_BLOCK.DESCRIPTION.PLACEHOLDER')
        "
        class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7 font-mono"
      />
    </div>

    <div class="bg-n-blue-2 border border-n-blue-7 rounded-lg p-3">
      <div class="flex items-start gap-2">
        <i class="i-lucide-info text-n-blue-11" />
        <p class="text-xs text-n-blue-11">
          Payment requests require Apple Pay or compatible payment processor
          configuration. Use parameters to dynamically set amount and
          description.
        </p>
      </div>
    </div>
  </div>
</template>
