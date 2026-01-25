<script setup>
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';

import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  icon: {
    type: String,
    default: 'i-lucide-inbox',
  },
});

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
      <i :class="[icon, 'text-3xl text-n-slate-11']" />
    </div>

    <h1 class="text-xl font-semibold text-n-slate-12 mb-2 text-center">
      {{ title }}
    </h1>

    <p
      class="text-sm text-n-slate-11 text-center max-w-md mb-8 leading-relaxed"
    >
      {{ description }}
    </p>

    <Button icon="i-lucide-plus" @click="navigateToCreateInbox">
      {{ t('CAMPAIGN.NO_INBOX.CREATE_INBOX_BUTTON') }}
    </Button>
  </div>
</template>

