<script setup>
import { computed } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
const { currentAccount } = useAccount();

const getAccountId = computed(() => currentAccount.value.id.toString());
</script>

<template>
  <div class="flex flex-row">
    <div class="flex-grow-0 flex-shrink-0 flex-[25%] min-w-0 py-4 pr-6 pl-0">
      <h4 class="text-lg font-medium text-n-slate-12">
        {{ t('GENERAL_SETTINGS.FORM.ACCOUNT_ID.TITLE') }}
      </h4>
      <p class="text-n-slate-11">
        {{ t('GENERAL_SETTINGS.FORM.ACCOUNT_ID.NOTE') }}
      </p>
    </div>
    <div class="p-4 flex-grow-0 flex-shrink-0 flex-[50%]">
      <woot-code :script="getAccountId" />
    </div>
  </div>
</template>
