<script setup>
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useMapGetter } from 'dashboard/composables/store';

const { t, te } = useI18n();
const { isAdmin } = useAdmin();
const currentAccount = useMapGetter('getCurrentAccount');
const isOnChatwootCloud = useMapGetter('globalConfig/isOnChatwootCloud');

const showBillingLink = computed(
  () =>
    isAdmin.value &&
    isOnChatwootCloud.value &&
    [null, undefined, 'non_payment'].includes(
      currentAccount.value?.suspension_category
    )
);

const fallbackSuspensionMessage = () =>
  t('APP_GLOBAL.ACCOUNT_SUSPENDED.MESSAGE');

const suspensionMessage = computed(() => {
  switch (currentAccount.value?.suspension_category) {
    case 'spam':
      return te('APP_GLOBAL.ACCOUNT_SUSPENDED.MESSAGES.SPAM')
        ? t('APP_GLOBAL.ACCOUNT_SUSPENDED.MESSAGES.SPAM')
        : fallbackSuspensionMessage();
    case 'non_payment':
      if (showBillingLink.value) {
        return te('APP_GLOBAL.ACCOUNT_SUSPENDED.MESSAGES.NON_PAYMENT')
          ? t('APP_GLOBAL.ACCOUNT_SUSPENDED.MESSAGES.NON_PAYMENT')
          : fallbackSuspensionMessage();
      }
      return te('APP_GLOBAL.ACCOUNT_SUSPENDED.MESSAGES.NON_PAYMENT_SUPPORT')
        ? t('APP_GLOBAL.ACCOUNT_SUSPENDED.MESSAGES.NON_PAYMENT_SUPPORT')
        : fallbackSuspensionMessage();
    case 'other':
      return te('APP_GLOBAL.ACCOUNT_SUSPENDED.MESSAGES.OTHER')
        ? t('APP_GLOBAL.ACCOUNT_SUSPENDED.MESSAGES.OTHER')
        : fallbackSuspensionMessage();
    default:
      if (showBillingLink.value) {
        return te('APP_GLOBAL.ACCOUNT_SUSPENDED.MESSAGES.DEFAULT')
          ? t('APP_GLOBAL.ACCOUNT_SUSPENDED.MESSAGES.DEFAULT')
          : fallbackSuspensionMessage();
      }
      return te('APP_GLOBAL.ACCOUNT_SUSPENDED.MESSAGES.DEFAULT_SUPPORT')
        ? t('APP_GLOBAL.ACCOUNT_SUSPENDED.MESSAGES.DEFAULT_SUPPORT')
        : fallbackSuspensionMessage();
  }
});

const toggleSupportWidgetVisibility = () => {
  if (window.$chatwoot) {
    window.$chatwoot.toggleBubbleVisibility('show');
  }
};

const toggleSupportWidget = () => {
  if (window.$chatwoot) {
    window.$chatwoot.toggle();
  }
};

const setupListenerForWidgetEvent = () => {
  window.addEventListener('chatwoot:on-message', () => {
    toggleSupportWidgetVisibility();
  });
};

onMounted(() => {
  toggleSupportWidgetVisibility();
  setupListenerForWidgetEvent();
});
</script>

<template>
  <div class="items-center bg-n-slate-2 flex justify-center h-full w-full">
    <EmptyState
      class="max-w-lg"
      :title="$t('APP_GLOBAL.ACCOUNT_SUSPENDED.TITLE')"
      :message="suspensionMessage"
    >
      <div class="flex flex-col items-center gap-3 mt-4">
        <NextButton
          icon="i-lucide-life-buoy"
          :label="$t('SIDEBAR_ITEMS.CONTACT_SUPPORT')"
          @click="toggleSupportWidget"
        />
        <router-link
          v-if="showBillingLink"
          :to="{ name: 'billing_settings_index' }"
          class="text-sm text-n-slate-11 hover:text-n-slate-12 hover:underline"
        >
          {{ $t('APP_GLOBAL.ACCOUNT_SUSPENDED.MANAGE_BILLING') }}
        </router-link>
      </div>
    </EmptyState>
  </div>
</template>
