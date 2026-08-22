<script setup>
import { useI18n } from 'vue-i18n';
import Banner from 'dashboard/components-next/banner/Banner.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const { t } = useI18n();
</script>

<template>
  <Banner color="blue" class="w-full">
    <div class="flex items-start gap-3 text-start">
      <Icon icon="i-lucide-info" class="flex-shrink-0 mt-0.5 size-4" />
      <div class="min-w-0 flex flex-col gap-0.5">
        <span class="font-medium">
          {{ t('CAMPAIGN.WHATSAPP.ATTRIBUTION_NOTICE.TITLE') }}
        </span>
        <span>
          {{ t('CAMPAIGN.WHATSAPP.ATTRIBUTION_NOTICE.BODY') }}
        </span>
      </div>
    </div>
  </Banner>
</template>
