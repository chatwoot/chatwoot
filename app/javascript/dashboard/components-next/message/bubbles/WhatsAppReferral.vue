<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  referral: {
    type: Object,
    default: null,
  },
  referredProduct: {
    type: Object,
    default: null,
  },
});

const { t } = useI18n();

const isImage = computed(() => props.referral?.mediaType === 'image');

const sourceLabel = computed(() =>
  props.referral?.sourceType === 'ad'
    ? t('COMPONENTS.WHATSAPP_REFERRAL.AD')
    : t('COMPONENTS.WHATSAPP_REFERRAL.POST')
);
</script>

<template>
  <div class="flex flex-col gap-2">
    <a
      v-if="isImage && referral.imageUrl"
      :href="referral.sourceUrl"
      target="_blank"
      rel="noopener noreferrer"
    >
      <img
        :src="referral.imageUrl"
        class="rounded-lg w-full object-cover max-h-48"
      />
    </a>
    <div class="flex flex-col gap-1">
      <template v-if="referral">
        <span class="text-xs font-semibold uppercase text-n-slate-11">
          {{ sourceLabel }}
        </span>
        <p v-if="referral.headline" class="mb-0 font-medium text-sm">
          {{ referral.headline }}
        </p>
        <p v-if="referral.body" class="mb-0 text-sm text-n-slate-12">
          {{ referral.body }}
        </p>
        <a
          v-if="referral.sourceUrl"
          :href="referral.sourceUrl"
          target="_blank"
          rel="noopener noreferrer"
          class="text-sm font-semibold text-n-brand"
        >
          {{ t('COMPONENTS.WHATSAPP_REFERRAL.VIEW') }}
        </a>
        <span v-if="referral.sourceId" class="text-xs text-n-slate-11">
          {{ t('COMPONENTS.WHATSAPP_REFERRAL.AD_ID') }}: {{ referral.sourceId }}
        </span>
        <template v-if="referredProduct">
          <span
            v-if="referredProduct.catalogId"
            class="text-xs text-n-slate-11"
          >
            {{ t('COMPONENTS.WHATSAPP_REFERRAL.CATALOG_ID') }}:
            {{ referredProduct.catalogId }}
          </span>
          <span
            v-if="referredProduct.productRetailerId"
            class="text-xs text-n-slate-11"
          >
            {{ t('COMPONENTS.WHATSAPP_REFERRAL.PRODUCT_ID') }}:
            {{ referredProduct.productRetailerId }}
          </span>
        </template>
      </template>
    </div>
  </div>
</template>
