<script setup>
import { computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useAccount } from 'dashboard/composables/useAccount';
import { useBillingStore } from 'dashboard/stores/billing';
import { useI18n } from 'vue-i18n';

const router = useRouter();
const { isAdmin } = useAdmin();
const { accountId } = useAccount();
const billingStore = useBillingStore();
const { t } = useI18n();

onMounted(() => {
  if (!billingStore.subscription) {
    billingStore.fetch();
  }
});

const shouldShowPaywall = computed(() => {
  return billingStore.shouldShowPaywall;
});

const routeToBilling = () => {
  router.push({
    name: 'billing_settings_index',
    params: { accountId: accountId.value },
  });
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <div
    v-if="shouldShowPaywall"
    class="fixed inset-0 z-50 flex items-center justify-center bg-n-solid-1/80 backdrop-blur-sm"
  >
    <div
      class="w-full max-w-md p-8 mx-4 text-center rounded-2xl bg-n-solid-2 shadow-lg border border-n-strong"
    >
      <div
        class="flex items-center justify-center w-12 h-12 mx-auto mb-4 rounded-full bg-n-amber-3"
      >
        <span class="i-lucide-alert-triangle text-2xl text-n-amber-11" />
      </div>

      <h2 class="mb-2 text-lg font-semibold text-n-slate-12">
        {{ t('BILLING_SETTINGS.PAYWALL.TITLE') }}
      </h2>

      <p class="mb-6 text-sm text-n-slate-11">
        {{
          isAdmin
            ? t('BILLING_SETTINGS.PAYWALL.DESCRIPTION_ADMIN')
            : t('BILLING_SETTINGS.PAYWALL.DESCRIPTION_AGENT')
        }}
      </p>

      <button
        v-if="isAdmin"
        class="w-full px-4 py-2.5 text-sm font-medium text-white rounded-lg bg-n-brand hover:bg-n-brand/90 transition-colors"
        @click="routeToBilling"
      >
        {{ t('BILLING_SETTINGS.PAYWALL.ACTION') }}
      </button>
    </div>
  </div>
</template>
