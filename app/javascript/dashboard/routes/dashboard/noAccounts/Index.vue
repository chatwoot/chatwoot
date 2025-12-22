<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Auth from 'dashboard/api/auth';

const { t } = useI18n();
const isOnChatwootCloud = useMapGetter('globalConfig/isOnChatwootCloud');

const message = computed(() => {
  if (isOnChatwootCloud.value) {
    return t('APP_GLOBAL.NO_ACCOUNTS.MESSAGE_CLOUD');
  }
  return t('APP_GLOBAL.NO_ACCOUNTS.MESSAGE_SELF_HOSTED');
});

const handleLogout = () => {
  Auth.logout();
};
</script>

<template>
  <div
    class="flex flex-col flex-1 items-center justify-center w-full h-full gap-6 bg-n-slate-2"
  >
    <EmptyState
      :title="$t('APP_GLOBAL.NO_ACCOUNTS.TITLE')"
      :message="message"
    />
    <NextButton
      variant="smooth"
      color-scheme="secondary"
      :label="$t('APP_GLOBAL.NO_ACCOUNTS.LOGOUT')"
      @click="handleLogout"
    />
  </div>
</template>
