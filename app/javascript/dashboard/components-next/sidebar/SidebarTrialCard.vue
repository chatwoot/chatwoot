<script setup>
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { format } from 'date-fns';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useTrialStatus } from 'dashboard/composables/useTrialStatus';
import Button from 'dashboard/components-next/button/Button.vue';

const router = useRouter();
const { t } = useI18n();
const { accountId } = useAccount();
const { isAdmin } = useAdmin();
const {
  isTrialing,
  trialEndsAt,
  trialCancelsAt,
  trialDaysLeft,
  isTrialEndingSoon,
  trialPlanName,
} = useTrialStatus();

const isBillingPage = computed(
  () => router.currentRoute.value.name === 'billing_settings_index'
);

const description = computed(() =>
  trialCancelsAt.value
    ? t('SIDEBAR.TRIAL.DESCRIPTION_CANCELLED', {
        plan: trialPlanName.value,
        date: format(trialCancelsAt.value, 'dd MMM'),
      })
    : t('SIDEBAR.TRIAL.DESCRIPTION', {
        date: format(trialEndsAt.value, 'dd MMM'),
      })
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
  <div v-if="isTrialing && isAdmin && !isBillingPage" class="z-10 px-2 w-full">
    <div
      class="flex flex-col gap-1 p-3 rounded-lg border shadow-sm bg-n-card dark:bg-n-solid-1"
      :class="isTrialEndingSoon ? 'border-n-amber-7' : 'border-n-weak'"
    >
      <h5 class="mb-0 text-sm font-semibold text-n-slate-12">
        {{
          t(
            'SIDEBAR.TRIAL.TITLE',
            { plan: trialPlanName, days: trialDaysLeft },
            trialDaysLeft
          )
        }}
      </h5>
      <p class="mb-0 text-xs leading-relaxed text-n-slate-11">
        {{ description }}
      </p>
      <Button
        :label="t('SIDEBAR.TRIAL.ACTION')"
        color="slate"
        link
        sm
        class="self-start mt-1 text-xs font-normal hover:!no-underline"
        @click="openBilling"
      />
    </div>
  </div>
</template>
