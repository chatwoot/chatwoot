<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import ChannelIcon from 'dashboard/components-next/icon/ChannelIcon.vue';
import { useChannelConnect } from './useChannelConnect';
import InboxChannelForm from './InboxChannelForm.vue';

const props = defineProps({
  inboxes: { type: Array, default: () => [] },
});

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

const dialogRef = ref(null);

// Credential-form channels (Line, Telegram) swap the grid for an inline form;
// OAuth channels redirect; the rest are no-ops for now.
const selectedChannel = ref(null);

const onCardClick = channel => {
  if (channel.form) {
    selectedChannel.value = channel;
    return;
  }
  connectViaOAuth(OAUTH_PROVIDERS[channel.type]);
};

const dialogTitle = computed(() =>
  selectedChannel.value
    ? t('ONBOARDING_INBOX_SETUP.CHANNELS_DIALOG.CONNECT_TITLE', {
        name: selectedChannel.value.label,
      })
    : t('ONBOARDING_INBOX_SETUP.CHANNELS_DIALOG.TITLE')
);

const dialogDescription = computed(() =>
  selectedChannel.value
    ? t('ONBOARDING_INBOX_SETUP.CHANNELS_DIALOG.CONNECT_SUBTITLE')
    : t('ONBOARDING_INBOX_SETUP.CHANNELS_DIALOG.SUBTITLE')
);

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
    type: 'tiktok',
    label: 'TikTok',
    inbox: { channel_type: 'Channel::Tiktok' },
  },
  {
    type: 'line',
    label: 'LINE',
    inbox: { channel_type: 'Channel::Line' },
    form: true,
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
    type: 'telegram',
    label: 'Telegram',
    inbox: { channel_type: 'Channel::Telegram' },
    form: true,
  },
  {
    type: 'website',
    label: 'Website',
    inbox: { channel_type: 'Channel::WebWidget' },
  },
  {
    type: 'sms',
    label: 'SMS',
    inbox: { channel_type: 'Channel::Sms' },
    disabled: true,
  },
  {
    type: 'api',
    label: 'API',
    inbox: { channel_type: 'Channel::Api' },
    disabled: true,
  },
  {
    type: 'voice',
    label: 'Voice',
    fallbackIcon: 'i-woot-voice',
    disabled: true,
  },
  {
    type: 'email',
    label: 'Other Email Providers',
    fallbackIcon: 'i-woot-mail',
    disabled: true,
  },
];

// A channel is connected when a real inbox shares its channel_type. Gmail and
// Outlook both use Channel::Email, so for email we also match on provider.
const isConnected = inbox =>
  !!inbox &&
  props.inboxes.some(
    configured =>
      configured.channel_type === inbox.channel_type &&
      (inbox.channel_type !== 'Channel::Email' ||
        configured.provider === inbox.provider)
  );

const open = () => {
  selectedChannel.value = null;
  dialogRef.value?.open();
};
const close = () => dialogRef.value?.close();

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="dialogTitle"
    :description="dialogDescription"
    width="lg"
    :show-confirm-button="false"
    :show-cancel-button="false"
    @close="selectedChannel = null"
  >
    <InboxChannelForm
      v-if="selectedChannel"
      :channel="selectedChannel"
      @back="selectedChannel = null"
      @created="selectedChannel = null"
    />
    <template v-else>
      <div class="grid grid-cols-2 gap-3">
        <button
          v-for="channel in CHANNEL_LIST"
          :key="channel.type"
          type="button"
          :disabled="channel.disabled"
          class="flex items-center gap-3 p-3 rounded-xl outline outline-1 outline-n-weak shadow-[0px_1px_2px_0px_rgba(27,28,29,0.036)] transition-colors text-start"
          :class="
            channel.disabled
              ? 'bg-n-slate-2 cursor-not-allowed'
              : 'bg-n-solid-1 hover:outline-n-slate-6 cursor-pointer'
          "
          @click="onCardClick(channel)"
        >
          <div
            class="size-9 rounded-[10px] outline outline-1 outline-n-weak flex items-center justify-center flex-shrink-0"
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
            v-if="isConnected(channel.inbox)"
            icon="i-lucide-circle-check"
            class="size-5 text-n-teal-11"
          />
          <Icon
            v-else-if="!channel.disabled"
            icon="i-lucide-chevron-right"
            class="size-5 text-n-slate-9"
          />
        </button>
      </div>
      <p class="text-sm text-n-slate-11">
        {{ t('ONBOARDING_INBOX_SETUP.CHANNELS_DIALOG.NOTE') }}
      </p>
    </template>
  </Dialog>
</template>
