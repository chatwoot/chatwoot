<script setup>
import { useI18n } from 'vue-i18n';
import ChannelIcon from 'dashboard/components-next/icon/ChannelIcon.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

defineProps({
  channel: { type: Object, required: true },
});

defineEmits(['connect']);

const { t } = useI18n();
</script>

<template>
  <div class="flex items-center justify-between gap-3 px-3 py-3">
    <div class="flex items-center gap-2 min-w-0">
      <ChannelIcon
        :inbox="channel.inbox"
        use-image
        class="size-4 flex-shrink-0"
      />
      <span class="text-sm font-medium text-n-slate-12">
        {{ channel.label }}
      </span>
    </div>
    <NextButton outline slate xs @click="$emit('connect', channel)">
      <span class="text-n-blue-11 truncate">
        {{
          t('ONBOARDING_INBOX_SETUP.CHANNELS.CONNECT', {
            name: channel.handle || channel.label,
          })
        }}
      </span>
    </NextButton>
  </div>
</template>
