<script setup>
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import {
  getShopifyInstallAccount,
  getShopifyInstallPath,
} from 'v3/helpers/AuthHelper';
import { frontendURL } from 'dashboard/helper/URLHelper';
import Button from 'dashboard/components-next/button/Button.vue';

const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const user = useMapGetter('getCurrentUser');
const accounts = computed(() =>
  (user.value.accounts || []).filter(account =>
    getShopifyInstallAccount({ accounts: [account], accountId: account.id })
  )
);
const token = computed(() => route.query.shopify_pending_install);
const validToken = computed(
  () => typeof token.value === 'string' && /^[0-9a-f]{32}$/.test(token.value)
);
const selectAccount = account => {
  const redirect = `settings/integrations/shopify?shopify_pending_install=${token.value}`;
  router.push(
    frontendURL(
      `accounts/${account.id}/${getShopifyInstallPath(account, redirect)}`
    )
  );
};
</script>

<template>
  <div
    class="flex min-h-screen items-center justify-center bg-n-background p-6"
  >
    <div
      class="flex w-full max-w-lg flex-col gap-4 rounded-xl bg-n-solid-1 p-6 shadow"
    >
      <h1 class="text-xl font-semibold text-n-slate-12">
        {{ t('INTEGRATION_SETTINGS.SHOPIFY.SELECT_ACCOUNT.TITLE') }}
      </h1>
      <p class="text-n-slate-11">
        {{ t('INTEGRATION_SETTINGS.SHOPIFY.SELECT_ACCOUNT.DESCRIPTION') }}
      </p>
      <template v-if="validToken && accounts.length">
        <Button
          v-for="account in accounts"
          :key="account.id"
          :label="account.name"
          @click="selectAccount(account)"
        />
      </template>
      <p v-else class="text-n-ruby-9">
        {{ t('INTEGRATION_SETTINGS.SHOPIFY.SELECT_ACCOUNT.UNAVAILABLE') }}
      </p>
    </div>
  </div>
</template>
