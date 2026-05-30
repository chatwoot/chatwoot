<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
  inboxId: {
    type: [String, Number],
    required: true,
  },
});

const { t } = useI18n();

const isImapSmtpInbox = computed(() => {
  return props.inbox.imap_enabled;
});

const message = computed(() => {
  return isImapSmtpInbox.value
    ? t('INBOX_MGMT.ADD.EMAIL_CHANNEL.FINISH_MESSAGE_IMAP_SMTP')
    : t('INBOX_MGMT.ADD.EMAIL_CHANNEL.FINISH_MESSAGE_FORWARDING');
});

const showForwardingAddress = computed(() => {
  return !isImapSmtpInbox.value && props.inbox.forwarding_enabled;
});
</script>

<template>
  <div class="w-full text-center flex flex-col items-center">
    <p class="text-base text-n-slate-11 mt-4 max-w-2xl leading-7">
      {{ message }}
    </p>

    <div v-if="showForwardingAddress" class="w-full max-w-xl mt-8">
      <p class="mb-4 font-medium text-n-slate-11">
        {{ $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.FORWARDING_ADDRESS_LABEL') }}
      </p>
      <woot-code lang="html" :script="inbox.forward_to_email" />
      <p class="mt-4 text-sm text-n-slate-11 max-w-md mx-auto leading-6">
        {{ $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.FORWARDING_RULE_HELP') }}
      </p>
    </div>

    <p
      v-if="isImapSmtpInbox"
      class="mt-8 text-sm text-n-slate-11 pb-4 max-w-xl leading-6"
    >
      <router-link
        :to="{
          name: 'settings_inbox_show',
          params: { inboxId: inboxId, tab: 'configuration' },
        }"
        class="text-n-woot-600 hover:text-n-woot-700 underline"
      >
        {{ $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.CONFIGURE_EMAIL_SETTINGS_LINK') }}
      </router-link>
      {{ $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.MANAGE_SMTP_IMAP_TEXT') }}
    </p>
  </div>
</template>
