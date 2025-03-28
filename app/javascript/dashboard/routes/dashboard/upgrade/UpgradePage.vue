<script setup>
import { onMounted, computed, defineExpose, defineProps } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { differenceInDays } from 'date-fns';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useI18n } from 'vue-i18n';

import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  bypassUpgradePage: {
    type: Boolean,
    default: false,
  },
});

const router = useRouter();
const store = useStore();
const { t } = useI18n();
const { accountId, currentAccount } = useAccount();
const { isAdmin } = useAdmin();

const isOnChatwootCloud = useMapGetter('globalConfig/isOnChatwootCloud');

const testLimit = ({ allowed, consumed }) => {
  return consumed > allowed;
};

const isTrialAccount = computed(() => {
  // check if account is less than 15 days old
  const account = currentAccount.value;
  if (!account) return false;

  const createdAt = new Date(account.created_at);
  const diffDays = differenceInDays(new Date(), createdAt);

  return diffDays <= 15;
});

const limitExceededMessage = computed(() => {
  const account = currentAccount.value;
  if (!account?.limits) return '';

  const {
    conversation,
    non_web_inboxes: nonWebInboxes,
    agents,
  } = account.limits;

  let message = '';

  if (testLimit(conversation)) {
    message = t('GENERAL_SETTINGS.LIMIT_MESSAGES.CONVERSATION');
  } else if (testLimit(nonWebInboxes)) {
    message = t('GENERAL_SETTINGS.LIMIT_MESSAGES.INBOXES');
  } else if (testLimit(agents)) {
    message = t('GENERAL_SETTINGS.LIMIT_MESSAGES.AGENTS');
  }

  return message;
});

const isLimitExceeded = computed(() => {
  const account = currentAccount.value;
  if (!account?.limits) return false;

  const {
    conversation,
    non_web_inboxes: nonWebInboxes,
    agents,
  } = account.limits;

  return (
    testLimit(conversation) || testLimit(nonWebInboxes) || testLimit(agents)
  );
});

const shouldShowUpgradePage = computed(() => {
  // Skip upgrade page in Billing, Inbox, and Agent pages
  if (props.bypassUpgradePage) return false;
  if (!isOnChatwootCloud.value) return false;
  if (isTrialAccount.value) return false;
  return isLimitExceeded.value;
});

const fetchLimits = () => {
  store.dispatch('accounts/limits');
};

const routeToBilling = () => {
  router.push({
    name: 'billing_settings_index',
    params: { accountId: accountId.value },
  });
};

onMounted(() => fetchLimits());

defineExpose({ shouldShowUpgradePage });
</script>

<template>
  <template v-if="shouldShowUpgradePage">
    <div class="mx-auto h-full pt-[clamp(3rem,15vh,12rem)]">
      <div
        class="flex flex-col gap-4 max-w-md px-8 py-6 shadow-lg bg-n-solid-1 rounded-xl outline outline-1 outline-n-container"
      >
        <div class="flex flex-col gap-4">
          <div class="flex items-center w-full gap-2">
            <span
              class="flex items-center justify-center w-6 h-6 rounded-full bg-n-solid-blue"
            >
              <Icon
                class="flex-shrink-0 text-n-brand size-[14px]"
                icon="i-lucide-lock-keyhole"
              />
            </span>
            <span class="text-base font-medium text-n-slate-12">
              {{ $t('GENERAL_SETTINGS.UPGRADE') }}
            </span>
          </div>
          <div>
            <p class="text-sm font-normal text-n-slate-11 mb-3">
              {{ limitExceededMessage }}
            </p>
            <p v-if="!isAdmin">
              {{ t('GENERAL_SETTINGS.LIMIT_MESSAGES.NON_ADMIN') }}
            </p>
          </div>
        </div>
        <NextButton
          v-if="isAdmin"
          :label="$t('GENERAL_SETTINGS.OPEN_BILLING')"
          icon="i-lucide-credit-card"
          @click="routeToBilling()"
        />
      </div>
    </div>
  </template>
  <template v-else />
</template>
