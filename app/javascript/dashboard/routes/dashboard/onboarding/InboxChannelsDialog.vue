<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import ChannelIcon from 'dashboard/components-next/icon/ChannelIcon.vue';
import { useChannelConnect } from './useChannelConnect';

const props = defineProps({
  connectedTypes: { type: Array, default: () => [] },
});

const emit = defineEmits(['continue', 'skip']);

const { t } = useI18n();
const { connectViaOAuth } = useChannelConnect();

// Maps the dialog's display types to the OAuth client key the flow expects.
// Types without an entry (manual-setup channels) are no-ops for now.
const OAUTH_PROVIDERS = {
  gmail: 'google',
  outlook: 'microsoft',
  instagram: 'instagram',
  tiktok: 'tiktok',
};

const connect = type => connectViaOAuth(OAUTH_PROVIDERS[type]);

const dialogRef = ref(null);

// `inbox` is a stub shaped like a real inbox so ChannelIcon can resolve the
// icon from the shared provider. With `use-brand-icon`, ChannelIcon renders the
// full-color brand logo when one exists and falls back to the monochrome glyph
// otherwise, so no per-channel style flag is needed. Entries without a channel
// type (Voice, Other Email Providers) render `fallbackIcon` instead.
const CHANNEL_LIST = [
  {
    type: 'whatsapp',
    label: 'WhatsApp',
    inbox: { channel_type: 'Channel::Whatsapp' },
  },
  {
    type: 'instagram',
    label: 'Instagram',
    inbox: { channel_type: 'Channel::Instagram' },
  },
  {
    type: 'facebook',
    label: 'Facebook',
    inbox: { channel_type: 'Channel::FacebookPage' },
  },
  {
    type: 'sms',
    label: 'SMS',
    inbox: { channel_type: 'Channel::Sms' },
  },
  {
    type: 'tiktok',
    label: 'TikTok',
    inbox: { channel_type: 'Channel::Tiktok' },
  },
  {
    type: 'line',
    label: 'LINE',
    inbox: { channel_type: 'Channel::Line' },
  },
  {
    type: 'gmail',
    label: 'Gmail',
    inbox: { channel_type: 'Channel::Email', provider: 'google' },
  },
  {
    type: 'outlook',
    label: 'Outlook',
    inbox: { channel_type: 'Channel::Email', provider: 'microsoft' },
  },
  {
    type: 'api',
    label: 'API',
    inbox: { channel_type: 'Channel::Api' },
  },
  {
    type: 'website',
    label: 'Website',
    inbox: { channel_type: 'Channel::WebWidget' },
  },
  {
    type: 'telegram',
    label: 'Telegram',
    inbox: { channel_type: 'Channel::Telegram' },
  },
  {
    type: 'voice',
    label: 'Voice',
    fallbackIcon: 'i-woot-voice',
  },
  {
    type: 'email',
    label: 'Other Email Providers',
    fallbackIcon: 'i-woot-mail',
  },
];

const isConnected = type => props.connectedTypes.includes(type);

const open = () => dialogRef.value?.open();
const close = () => dialogRef.value?.close();

defineExpose({ open, close });

const handleContinue = () => {
  emit('continue');
  close();
};

const handleSkip = () => {
  emit('skip');
  close();
};
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('ONBOARDING_INBOX_SETUP.CHANNELS_DIALOG.TITLE')"
    :description="t('ONBOARDING_INBOX_SETUP.CHANNELS_DIALOG.SUBTITLE')"
    width="2xl"
    @confirm="handleContinue"
  >
    <div class="grid grid-cols-2 gap-3">
      <button
        v-for="channel in CHANNEL_LIST"
        :key="channel.type"
        type="button"
        class="flex items-center gap-3 p-3 rounded-[10px] bg-n-solid-1 outline outline-1 outline-n-weak hover:outline-n-slate-6 transition-colors text-start cursor-pointer"
        @click="connect(channel.type)"
      >
        <div
          class="size-9 rounded-md outline outline-1 outline-n-weak flex items-center justify-center flex-shrink-0"
        >
          <ChannelIcon
            v-if="channel.inbox"
            :inbox="channel.inbox"
            use-brand-icon
            class="size-5 text-n-slate-11"
          />
          <Icon
            v-else
            :icon="channel.fallbackIcon"
            class="size-4 text-n-slate-11"
          />
        </div>
        <span class="flex-1 text-sm font-medium text-n-slate-12">
          {{ channel.label }}
        </span>
        <Icon
          v-if="isConnected(channel.type)"
          icon="i-lucide-circle-check"
          class="size-5 text-n-teal-11"
        />
        <Icon
          v-else
          icon="i-lucide-chevron-right"
          class="size-5 text-n-slate-9"
        />
      </button>
    </div>
    <p class="text-sm text-n-slate-11">
      {{ t('ONBOARDING_INBOX_SETUP.CHANNELS_DIALOG.NOTE') }}
    </p>
    <template #footer>
      <div class="flex items-center w-full gap-3">
        <NextButton
          type="submit"
          blue
          class="flex-1 justify-center"
          :label="t('ONBOARDING_INBOX_SETUP.CONTINUE')"
        />
        <NextButton
          type="button"
          slate
          faded
          class="flex-1 justify-center"
          :label="t('ONBOARDING_INBOX_SETUP.SKIP')"
          @click="handleSkip"
        />
      </div>
    </template>
  </Dialog>
</template>
