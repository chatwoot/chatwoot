<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Banner from 'dashboard/components-next/banner/Banner.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const emit = defineEmits(['start']);
const { t } = useI18n();

const WHATSAPP_MANUAL_MIGRATION_GUIDE_URL =
  'https://www.chatwoot.com/hc/user-guide/articles/1756799850-how-to-setup-a-whats_app-channel-manual-flow';

const copy = computed(() => ({
  title: t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.BANNER.TITLE'),
  description: t(
    'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.BANNER.DESCRIPTION'
  ),
  start: t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.BANNER.START'),
  guide: t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.BANNER.GUIDE'),
}));
</script>

<template>
  <Banner color="amber" :action-label="copy.start" @action="emit('start')">
    <div class="flex items-start gap-2">
      <Icon
        icon="i-lucide-triangle-alert"
        class="flex-shrink-0 mt-0.5 size-4 text-n-amber-11"
      />
      <div class="flex flex-col gap-0.5">
        <span class="font-medium text-n-amber-12">{{ copy.title }}</span>
        <span>
          {{ copy.description }}
          <a
            :href="WHATSAPP_MANUAL_MIGRATION_GUIDE_URL"
            target="_blank"
            rel="noopener noreferrer"
            class="underline link underline-offset-2"
          >
            {{ copy.guide }}
          </a>
        </span>
      </div>
    </div>
  </Banner>
</template>
