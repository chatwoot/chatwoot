<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import BillingCard from '../../billing/components/BillingCard.vue';
import CreditsBalance from './CreditsBalance.vue';
import TopupOptions from './TopupOptions.vue';
import CreditGrants from './CreditGrants.vue';
import Notice from 'dashboard/components-next/notice/Notice.vue';

defineProps({
  balanceData: {
    type: Object,
    default: () => null,
  },
  topupOptions: {
    type: Array,
    default: () => [],
  },
  creditGrants: {
    type: Array,
    default: () => [],
  },
  isLoadingBalance: {
    type: Boolean,
    default: false,
  },
  isLoadingTopup: {
    type: Boolean,
    default: false,
  },
  isLoadingGrants: {
    type: Boolean,
    default: false,
  },
  isProcessingTopup: {
    type: Boolean,
    default: false,
  },
  canUseTopup: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['refresh']);

const { t } = useI18n();

const showTopupOptions = ref(false);
const showCreditHistory = ref(false);

const handleViewTopup = () => {
  showTopupOptions.value = !showTopupOptions.value;
  if (showTopupOptions.value) {
    showCreditHistory.value = false;
  }
};

const handleViewHistory = () => {
  showCreditHistory.value = !showCreditHistory.value;
  if (showCreditHistory.value) {
    showTopupOptions.value = false;
  }
};

const handleRefresh = () => {
  emit('refresh');
};
</script>

<template>
  <BillingCard
    :title="t('BILLING_SETTINGS_V2.CREDITS_BALANCE.TITLE')"
    :description="t('BILLING_SETTINGS_V2.CREDITS_BALANCE.DESCRIPTION')"
  >
    <CreditsBalance
      :balance-data="balanceData"
      :is-loading="isLoadingBalance"
      @refresh="handleRefresh"
      @view-topup="handleViewTopup"
      @view-history="handleViewHistory"
    />

    <div
      class="transition-all duration-300 ease-out grid overflow-hidden mx-5 !mt-0"
      :class="
        showTopupOptions
          ? 'grid-rows-[1fr] opacity-100'
          : 'grid-rows-[0fr] opacity-0'
      "
    >
      <div class="overflow-hidden">
        <TopupOptions
          v-if="canUseTopup"
          :options="topupOptions"
          :is-loading="isLoadingTopup"
          :is-processing="isProcessingTopup"
        />
        <div v-else class="mt-4">
          <Notice
            color="amber"
            icon="i-lucide-alert-triangle"
            :title="t('BILLING_SETTINGS_V2.TOPUP_OPTIONS.UPGRADE_REQUIRED')"
            :message="t('BILLING_SETTINGS_V2.TOPUP_OPTIONS.UPGRADE_MESSAGE')"
          />
        </div>
      </div>
    </div>

    <div
      class="transition-all duration-300 ease-out grid overflow-hidden !mt-0"
      :class="
        showCreditHistory
          ? 'grid-rows-[1fr] opacity-100'
          : 'grid-rows-[0fr] opacity-0'
      "
    >
      <div class="overflow-hidden">
        <CreditGrants :grants="creditGrants" :is-loading="isLoadingGrants" />
      </div>
    </div>
  </BillingCard>
</template>
