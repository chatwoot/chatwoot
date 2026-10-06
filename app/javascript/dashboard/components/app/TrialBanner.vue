<script setup>
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { format } from 'date-fns';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useTrialStatus } from 'dashboard/composables/useTrialStatus';
import Banner from 'dashboard/components-next/banner/Banner.vue';

const router = useRouter();
const { t } = useI18n();
const { accountId } = useAccount();
const { isAdmin } = useAdmin();
const {
  isTrialing,
  trialEndsAt,
  trialDaysLeft,
  isTrialEndingSoon,
  trialPlanName,
} = useTrialStatus();

const isBillingPage = computed(
  () => router.currentRoute.value.name === 'billing_settings_index'
);

const message = computed(() =>
  t(
    'GENERAL_SETTINGS.TRIAL_BANNER.MESSAGE',
    {
      plan: trialPlanName.value,
      days: trialDaysLeft.value,
      date: format(trialEndsAt.value, 'dd MMM'),
    },
    trialDaysLeft.value
  )
);

const openBilling = () => {
  router.push({
    name: 'billing_settings_index',
    params: { accountId: accountId.value },
  });
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <Banner
    v-if="isTrialing && isAdmin && !isBillingPage"
    :color="isTrialEndingSoon ? 'amber' : 'blue'"
    class="!rounded-none !justify-center flex-wrap shrink-0"
    :action-label="t('GENERAL_SETTINGS.TRIAL_BANNER.ACTION')"
    @action="openBilling"
  >
    {{ message }}
  </Banner>
</template>
