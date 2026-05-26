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

// `inbox` here is a stub shaped like a real inbox so ChannelIcon can resolve
// the brand image / monochrome glyph from the shared provider.
// iconStyle:
//   - 'logo'         → brand logo fills the icon slot, no surrounding frame
//                    (logos that already carry their own colored background).
//   - 'framed-image' → brand image sits inside a bordered square (logos that
//                    are glyphs on transparent/white, e.g. Gmail, Outlook).
//   - 'framed-icon'  → svg glyph inside a bordered square.
// `fallbackIcon` is used for entries that don't map to a real channel type
// (e.g. the "Voice" and "Other Email Providers" groupings).
const CHANNEL_LIST = [
  {
    type: 'whatsapp',
    label: 'WhatsApp',
    inbox: { channel_type: 'Channel::Whatsapp' },
    iconStyle: 'framed-image',
  },
  {
    type: 'instagram',
    label: 'Instagram',
    inbox: { channel_type: 'Channel::Instagram' },
    iconStyle: 'framed-image',
  },
  {
    type: 'facebook',
    label: 'Facebook',
    inbox: { channel_type: 'Channel::FacebookPage' },
    iconStyle: 'framed-image',
  },
  {
    type: 'sms',
    label: 'SMS',
    inbox: { channel_type: 'Channel::Sms' },
    iconStyle: 'framed-icon',
  },
  {
    type: 'tiktok',
    label: 'TikTok',
    inbox: { channel_type: 'Channel::Tiktok' },
    iconStyle: 'framed-image',
  },
  {
    type: 'line',
    label: 'LINE',
    inbox: { channel_type: 'Channel::Line' },
    iconStyle: 'framed-image',
  },
  {
    type: 'gmail',
    label: 'Gmail',
    inbox: { channel_type: 'Channel::Email', provider: 'google' },
    iconStyle: 'framed-image',
  },
  {
    type: 'outlook',
    label: 'Outlook',
    inbox: { channel_type: 'Channel::Email', provider: 'microsoft' },
    iconStyle: 'framed-image',
  },
  {
    type: 'api',
    label: 'API',
    inbox: { channel_type: 'Channel::Api' },
    iconStyle: 'framed-icon',
  },
  {
    type: 'website',
    label: 'Website',
    inbox: { channel_type: 'Channel::WebWidget' },
    iconStyle: 'framed-icon',
  },
  {
    type: 'telegram',
    label: 'Telegram',
    inbox: { channel_type: 'Channel::Telegram' },
    iconStyle: 'framed-image',
  },
  {
    type: 'voice',
    label: 'Voice',
    fallbackIcon: 'i-woot-voice',
    iconStyle: 'framed-icon',
  },
  {
    type: 'email',
    label: 'Other Email Providers',
    fallbackIcon: 'i-woot-mail',
    iconStyle: 'framed-icon',
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
        <ChannelIcon
          v-if="channel.iconStyle === 'logo'"
          :inbox="channel.inbox"
          use-brand-icon
          class="size-9 flex-shrink-0"
        />
        <div
          v-else
          class="size-9 rounded-md outline outline-1 outline-n-weak flex items-center justify-center flex-shrink-0"
        >
          <ChannelIcon
            v-if="channel.iconStyle === 'framed-image'"
            :inbox="channel.inbox"
            use-brand-icon
            class="size-5"
          />
          <ChannelIcon
            v-else-if="channel.inbox"
            :inbox="channel.inbox"
            class="size-4 text-n-slate-11"
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
