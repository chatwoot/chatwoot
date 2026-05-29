<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  conversationAttributes: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();

const adSourceData = computed(() => {
  const attrs = props.conversationAttributes || {};
  
  // Check if we have ad source data
  if (!attrs.ad_source) {
    return null;
  }

  return {
    source: attrs.ad_source,
    sourceId: attrs.ad_source_id,
    sourceType: attrs.ad_source_type,
    sourceUrl: attrs.ad_source_url,
    adId: attrs.ad_id,
    adTitle: attrs.ad_title,
    adHeadline: attrs.ad_headline,
    adBody: attrs.ad_body,
    adRef: attrs.ad_ref,
    adRefererUri: attrs.ad_referer_uri,
    adCtwaCli: attrs.ad_ctwa_clid,
    mediaType: attrs.ad_media_type,
    mediaUrl: attrs.ad_media_url,
    photoUrl: attrs.photo_url,
    videoUrl: attrs.video_url,
    productId: attrs.product_id,
    referralFrom: attrs.referral_from,
    referredProductId: attrs.referred_product_id,
  };
});

const hasAdData = computed(() => !!adSourceData.value);

const adSourceLabel = computed(() => {
  const source = adSourceData.value?.source;
  if (source === 'whatsapp_ad') {
    return 'WhatsApp Ad';
  }
  if (source === 'instagram_ad') {
    return 'Instagram Ad';
  }
  return source;
});

const displayFields = computed(() => {
  if (!adSourceData.value) return [];
  
  const fields = [];
  const data = adSourceData.value;

  // Common fields
  if (data.sourceType) {
    fields.push({ label: t('CONVERSATION.AD_SOURCE.SOURCE_TYPE'), value: data.sourceType });
  }
  if (data.adId) {
    fields.push({ label: t('CONVERSATION.AD_SOURCE.AD_ID'), value: data.adId });
  }
  if (data.adTitle) {
    fields.push({ label: t('CONVERSATION.AD_SOURCE.AD_TITLE'), value: data.adTitle });
  }
  if (data.adHeadline) {
    fields.push({ label: t('CONVERSATION.AD_SOURCE.AD_HEADLINE'), value: data.adHeadline });
  }
  if (data.adRef) {
    fields.push({ label: t('CONVERSATION.AD_SOURCE.AD_REF'), value: data.adRef });
  }
  if (data.sourceId) {
    fields.push({ label: t('CONVERSATION.AD_SOURCE.SOURCE_ID'), value: data.sourceId });
  }
  if (data.adCtwaCli) {
    fields.push({ label: t('CONVERSATION.AD_SOURCE.CTWA_CLID'), value: data.adCtwaCli });
  }
  if (data.productId) {
    fields.push({ label: t('CONVERSATION.AD_SOURCE.PRODUCT_ID'), value: data.productId });
  }

  return fields;
});

const sourceUrl = computed(() => {
  return adSourceData.value?.sourceUrl || adSourceData.value?.adRefererUri;
});
</script>

<template>
  <div v-if="hasAdData" class="flex flex-col gap-2 py-3">
    <div class="flex items-center gap-2 pb-2">
      <fluent-icon icon="megaphone" size="16" class="text-primary" />
      <h4 class="text-sm font-medium text-n-strong">
        {{ adSourceLabel }}
      </h4>
    </div>
    
    <div class="flex flex-col gap-2">
      <div
        v-for="field in displayFields"
        :key="field.label"
        class="flex flex-col gap-0.5"
      >
        <span class="text-xs text-n-light">{{ field.label }}</span>
        <span class="text-sm text-n-strong break-words">{{ field.value }}</span>
      </div>

      <div v-if="sourceUrl" class="flex flex-col gap-0.5">
        <span class="text-xs text-n-light">
          {{ $t('CONVERSATION.AD_SOURCE.SOURCE_URL') }}
        </span>
        <a
          :href="sourceUrl"
          target="_blank"
          rel="noopener noreferrer"
          class="text-sm text-primary hover:underline break-all"
        >
          {{ sourceUrl }}
        </a>
      </div>
    </div>
  </div>
</template>
