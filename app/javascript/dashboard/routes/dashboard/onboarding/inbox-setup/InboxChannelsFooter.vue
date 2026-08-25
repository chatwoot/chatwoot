<script setup>
import { computed } from 'vue';
import { useI18n, I18nT } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import ChannelIcon from 'dashboard/components-next/icon/ChannelIcon.vue';
import { FALLBACK_PREVIEW_CHANNELS } from './constants';
import { useChannelConfig } from './useChannelConfig';

const props = defineProps({
  remainingChannels: { type: Array, default: () => [] },
});

defineEmits(['viewAll']);

const { t } = useI18n();
const { isConfigured } = useChannelConfig();

// Icons shown next to "View all". Defaults to the unconnected socials, but when
// everything detected is already connected we still want a hint of what's
// behind the dialog — fall back to a representative trio. Either way, drop
// channels whose installation credentials are missing so we never preview an
// icon the dialog itself hides.
const previewChannels = computed(() =>
  (props.remainingChannels.length
    ? props.remainingChannels
    : FALLBACK_PREVIEW_CHANNELS
  ).filter(channel => isConfigured(channel.type))
);
</script>

<template>
  <div class="flex items-center gap-2 px-3 pt-3 pb-4">
    <Icon icon="i-lucide-info" class="size-4 text-n-slate-9 flex-shrink-0" />
    <I18nT
      keypath="ONBOARDING_INBOX_SETUP.CHANNELS.MORE_CHANNELS_NOTE"
      tag="span"
      class="flex-1 min-w-0 text-body-main text-n-slate-11"
    >
      <template #email>
        <span class="text-n-slate-12">
          {{ t('ONBOARDING_INBOX_SETUP.CHANNELS.MORE_CHANNELS_EMAIL') }}
        </span>
      </template>
      <template #voice>
        <span class="text-n-slate-12">
          {{ t('ONBOARDING_INBOX_SETUP.CHANNELS.MORE_CHANNELS_VOICE') }}
        </span>
      </template>
    </I18nT>
    <div class="flex items-center gap-2 flex-shrink-0">
      <ChannelIcon
        v-for="channel in previewChannels"
        :key="channel.type"
        :inbox="channel.inbox"
        use-brand-icon
        class="size-5"
      />
    </div>
    <div class="flex items-center gap-2 flex-shrink-0 ps-1">
      <span class="w-px h-3 bg-n-weak" />
      <button
        type="button"
        class="text-button text-n-slate-12 hover:underline"
        @click="$emit('viewAll')"
      >
        {{ t('ONBOARDING_INBOX_SETUP.CHANNELS.VIEW_ALL') }}
      </button>
    </div>
  </div>
</template>
