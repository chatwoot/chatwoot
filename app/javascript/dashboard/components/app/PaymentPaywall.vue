<script setup>
import { computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useAccount } from 'dashboard/composables/useAccount';
import { differenceInDays } from 'date-fns';
import { useRoute } from 'vue-router';

const ALWAYS_ON_ROUTES = [
  'agent_list',
  'settings_inbox_list',
  'billing_settings_index',
];

const { accountId } = useAccount();
const store = useStore();
const route = useRoute();
const routeName = computed(() => {
  return route.name || '';
});
const isOnChatwootCloud = computed(
  () => store.getters['globalConfig/isOnChatwootCloud']
);
const account = computed(() =>
  store.getters['accounts/getAccount'](accountId.value)
);

const isTrialAccount = computed(() => {
  if (!account.value) return false;

  const createdAt = new Date(account.value.created_at);
  const diffDays = differenceInDays(new Date(), createdAt);

  return diffDays <= 15;
});

const testLimit = ({ allowed, consumed }) => {
  return consumed > allowed;
};

const isLimitExceeded = computed(() => {
  if (ALWAYS_ON_ROUTES.includes(routeName.value)) {
    return false;
  }

  if (!account.value) return false;

  const { limits } = account.value;
  if (!limits) return false;

  const { conversation, non_web_inboxes: nonWebInboxes } = limits;
  return testLimit(conversation) || testLimit(nonWebInboxes);
});

const shouldShowBanner = computed(() => {
  if (!isOnChatwootCloud.value) {
    return false;
  }

  if (isTrialAccount.value) {
    return false;
  }

  return isLimitExceeded.value;
});

const fetchLimits = () => store.dispatch('accounts/limits');

onMounted(() => {
  if (isOnChatwootCloud.value) {
    fetchLimits();
  }
});
</script>

<template>
  <div v-if="shouldShowBanner">Limits exceeded</div>

  <slot v-else />
</template>
