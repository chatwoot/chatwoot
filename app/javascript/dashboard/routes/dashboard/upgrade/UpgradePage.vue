<script setup>
import { onMounted, computed, defineExpose, defineProps } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { differenceInDays } from 'date-fns';

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
const { accountId, currentAccount } = useAccount();

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

const isLimitExceeded = computed(() => {
  const account = currentAccount.value;
  if (!account) return false;

  const { limits } = account;
  if (!limits) return false;

  const { conversation, non_web_inboxes: nonWebInboxes } = limits;
  return testLimit(conversation) || testLimit(nonWebInboxes);
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

onMounted(() => {
  fetchLimits();
});

defineExpose({
  shouldShowUpgradePage,
});
</script>

<template>
  <template v-if="shouldShowUpgradePage">
    <div class="mx-auto h-full pt-[clamp(3rem,15vh,12rem)]">
      <div
        class="flex flex-col gap-4 max-w-md px-8 py-6 shadow-lg bg-n-solid-1 rounded-xl outline outline-1 outline-n-container"
      >
        <div class="flex flex-col gap-2">
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
          <p class="text-sm font-normal text-n-slate-11">
            {{ $t('GENERAL_SETTINGS.LIMITS_UPGRADE') }}
          </p>
        </div>
        <NextButton
          :label="$t('GENERAL_SETTINGS.OPEN_BILLING')"
          icon="i-lucide-credit-card"
          @click="routeToBilling()"
        />
      </div>
    </div>
  </template>
  <template v-else />
</template>
