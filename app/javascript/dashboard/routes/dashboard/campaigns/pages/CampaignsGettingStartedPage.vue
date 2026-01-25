<script setup>
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';

import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const router = useRouter();
const { accountScopedRoute } = useAccount();

const navigateToCreateInbox = () => {
  router.push(accountScopedRoute('settings_inbox_new'));
};
</script>

<template>
  <div class="flex flex-col items-center justify-center flex-1 py-16 px-6">
    <div
      class="flex items-center justify-center w-16 h-16 mb-6 rounded-2xl bg-n-alpha-2"
    >
      <i class="i-lucide-megaphone text-3xl text-n-slate-11" />
    </div>

    <h1 class="text-xl font-semibold text-n-slate-12 mb-2 text-center">
      {{ t('CAMPAIGN.GETTING_STARTED.TITLE') }}
    </h1>

    <p
      class="text-sm text-n-slate-11 text-center max-w-lg mb-8 leading-relaxed"
    >
      {{ t('CAMPAIGN.GETTING_STARTED.DESCRIPTION') }}
    </p>

    <div class="flex flex-col gap-4 w-full max-w-md mb-8">
      <!-- Live Chat -->
      <div class="flex items-start gap-4 p-4 rounded-xl bg-n-alpha-1">
        <div
          class="flex items-center justify-center w-10 h-10 rounded-lg bg-n-alpha-2 flex-shrink-0"
        >
          <i class="i-lucide-message-circle text-lg text-n-slate-11" />
        </div>
        <div class="flex-1 min-w-0">
          <h3 class="text-sm font-medium text-n-slate-12 mb-1">
            {{ t('CAMPAIGN.GETTING_STARTED.LIVE_CHAT.TITLE') }}
          </h3>
          <p class="text-xs text-n-slate-11 leading-relaxed">
            {{ t('CAMPAIGN.GETTING_STARTED.LIVE_CHAT.DESCRIPTION') }}
          </p>
        </div>
      </div>

      <!-- SMS -->
      <div class="flex items-start gap-4 p-4 rounded-xl bg-n-alpha-1">
        <div
          class="flex items-center justify-center w-10 h-10 rounded-lg bg-n-alpha-2 flex-shrink-0"
        >
          <i class="i-lucide-smartphone text-lg text-n-slate-11" />
        </div>
        <div class="flex-1 min-w-0">
          <h3 class="text-sm font-medium text-n-slate-12 mb-1">
            {{ t('CAMPAIGN.GETTING_STARTED.SMS.TITLE') }}
          </h3>
          <p class="text-xs text-n-slate-11 leading-relaxed">
            {{ t('CAMPAIGN.GETTING_STARTED.SMS.DESCRIPTION') }}
          </p>
        </div>
      </div>

      <!-- WhatsApp -->
      <div class="flex items-start gap-4 p-4 rounded-xl bg-n-alpha-1">
        <div
          class="flex items-center justify-center w-10 h-10 rounded-lg bg-n-alpha-2 flex-shrink-0"
        >
          <i class="i-ri-whatsapp-line text-lg text-n-slate-11" />
        </div>
        <div class="flex-1 min-w-0">
          <h3 class="text-sm font-medium text-n-slate-12 mb-1">
            {{ t('CAMPAIGN.GETTING_STARTED.WHATSAPP.TITLE') }}
          </h3>
          <p class="text-xs text-n-slate-11 leading-relaxed">
            {{ t('CAMPAIGN.GETTING_STARTED.WHATSAPP.DESCRIPTION') }}
          </p>
        </div>
      </div>
    </div>

    <Button icon="i-lucide-plus" @click="navigateToCreateInbox">
      {{ t('CAMPAIGN.GETTING_STARTED.CREATE_INBOX_BUTTON') }}
    </Button>
  </div>
</template>

