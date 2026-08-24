<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { format } from 'date-fns';
import { useAlert } from 'dashboard/composables';
import whatsappUsageAPI from 'dashboard/api/whatsappUsage';
import whatsappTopupRequestsAPI from 'dashboard/api/whatsappTopupRequests';

import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BillingCard from '../billing/components/BillingCard.vue';
import DetailItem from '../billing/components/DetailItem.vue';
import ButtonV4 from 'next/button/Button.vue';

const { t } = useI18n();

const CREDIT_PACKAGES = [500, 1000, 2000, 5000, 10000];
const AMBER_USAGE_THRESHOLD_PERCENT = 60;
const RED_USAGE_THRESHOLD_PERCENT = 80;

const STATUS_BADGE_CLASSES = {
  approved: 'bg-n-teal-3 text-n-teal-11',
  pending: 'bg-n-amber-3 text-n-amber-11',
  rejected: 'bg-n-ruby-3 text-n-ruby-11',
};

const isFetching = ref(false);
const isRequestingTopup = ref(false);
const summary = ref(null);
const topupRequests = ref([]);
const selectedPackage = ref(CREDIT_PACKAGES[0]);

const remaining = computed(() => summary.value?.remaining ?? 0);
const isInDebt = computed(() => remaining.value < 0);

const usagePercent = computed(() => {
  const limit = summary.value?.limit ?? 0;
  if (limit <= 0) return remaining.value <= 0 ? 100 : 0;
  const used = summary.value?.used ?? 0;
  return Math.min(100, Math.max(0, (used / limit) * 100));
});

const balanceColorClass = computed(() => {
  if (isInDebt.value || usagePercent.value >= RED_USAGE_THRESHOLD_PERCENT) {
    return 'bg-n-ruby-10';
  }
  if (usagePercent.value >= AMBER_USAGE_THRESHOLD_PERCENT) {
    return 'bg-n-amber-10';
  }
  return 'bg-n-teal-10';
});

const statusBadgeClass = status =>
  STATUS_BADGE_CLASSES[status] || 'bg-n-slate-3 text-n-slate-11';

const formatDate = date => format(new Date(date), 'dd MMM, yyyy');

const fetchSummary = async () => {
  isFetching.value = true;
  try {
    const response = await whatsappUsageAPI.get();
    summary.value = response.data;
  } catch (error) {
    useAlert(t('WHATSAPP_USAGE.FETCH_ERROR'));
  } finally {
    isFetching.value = false;
  }
};

const fetchTopupRequests = async () => {
  try {
    const response = await whatsappTopupRequestsAPI.get();
    topupRequests.value = response.data;
  } catch (error) {
    useAlert(t('WHATSAPP_USAGE.HISTORY.FETCH_ERROR'));
  }
};

const requestTopup = async () => {
  isRequestingTopup.value = true;
  try {
    await whatsappTopupRequestsAPI.create({
      whatsapp_topup_request: { credits: selectedPackage.value },
    });
    useAlert(t('WHATSAPP_USAGE.TOPUP.SUCCESS'));
    fetchTopupRequests();
  } catch (error) {
    useAlert(t('WHATSAPP_USAGE.TOPUP.ERROR'));
  } finally {
    isRequestingTopup.value = false;
  }
};

onMounted(() => {
  fetchSummary();
  fetchTopupRequests();
});
</script>

<template>
  <SettingsLayout
    :is-loading="isFetching"
    :loading-message="t('ATTRIBUTES_MGMT.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('WHATSAPP_USAGE.TITLE')"
        :description="t('WHATSAPP_USAGE.DESCRIPTION')"
      />
    </template>
    <template #body>
      <section v-if="summary" class="grid gap-4">
        <BillingCard
          :title="t('WHATSAPP_USAGE.BALANCE.TITLE')"
          :description="t('WHATSAPP_USAGE.BALANCE.DESCRIPTION')"
        >
          <div
            v-if="isInDebt"
            class="mx-5 px-3 py-2 rounded-lg bg-n-ruby-3 text-n-ruby-11 text-sm"
          >
            {{
              t('WHATSAPP_USAGE.BALANCE.DEBT_WARNING', {
                count: Math.abs(remaining),
              })
            }}
          </div>
          <div class="px-5">
            <div class="rounded-full overflow-hidden h-2 w-full bg-n-slate-4">
              <div
                class="h-2 transition-all"
                :class="balanceColorClass"
                :style="{ width: `${usagePercent}%` }"
              />
            </div>
          </div>
          <div
            class="grid lg:grid-cols-4 sm:grid-cols-3 grid-cols-1 gap-2 divide-x divide-n-weak"
          >
            <DetailItem
              :label="t('WHATSAPP_USAGE.BALANCE.LIMIT')"
              :value="String(summary.limit)"
            />
            <DetailItem
              :label="t('WHATSAPP_USAGE.BALANCE.USED')"
              :value="String(summary.used)"
            />
            <DetailItem
              :label="t('WHATSAPP_USAGE.BALANCE.REMAINING')"
              :value="String(remaining)"
            />
          </div>
        </BillingCard>

        <BillingCard
          :title="t('WHATSAPP_USAGE.SPENT.TITLE')"
          :description="t('WHATSAPP_USAGE.SPENT.DESCRIPTION')"
        >
          <div
            class="grid lg:grid-cols-3 grid-cols-1 gap-2 divide-x divide-n-weak"
          >
            <DetailItem
              :label="t('WHATSAPP_USAGE.SPENT.TODAY')"
              :value="String(summary.spent_today)"
            />
            <DetailItem
              :label="t('WHATSAPP_USAGE.SPENT.WEEK')"
              :value="String(summary.spent_this_week)"
            />
            <DetailItem
              :label="t('WHATSAPP_USAGE.SPENT.MONTH')"
              :value="String(summary.spent_this_month)"
            />
          </div>
        </BillingCard>

        <BillingCard
          :title="t('WHATSAPP_USAGE.TOPUP.TITLE')"
          :description="t('WHATSAPP_USAGE.TOPUP.DESCRIPTION')"
        >
          <div class="px-5 flex flex-col gap-4">
            <div class="flex flex-wrap gap-2">
              <label
                v-for="pkg in CREDIT_PACKAGES"
                :key="pkg"
                class="px-4 py-2 rounded-lg border-2 cursor-pointer text-sm font-medium"
                :class="
                  selectedPackage === pkg
                    ? 'border-woot-500 text-n-slate-12'
                    : 'border-n-weak text-n-slate-11 hover:border-n-strong'
                "
              >
                <input
                  type="radio"
                  name="credit-package"
                  :value="pkg"
                  class="sr-only"
                  :checked="selectedPackage === pkg"
                  @change="selectedPackage = pkg"
                />
                {{ pkg.toLocaleString() }}
              </label>
            </div>
            <div>
              <ButtonV4
                sm
                solid
                blue
                :is-loading="isRequestingTopup"
                @click="requestTopup"
              >
                {{ t('WHATSAPP_USAGE.TOPUP.BUTTON_TXT') }}
              </ButtonV4>
            </div>
          </div>
        </BillingCard>

        <BillingCard
          :title="t('WHATSAPP_USAGE.HISTORY.TITLE')"
          :description="t('WHATSAPP_USAGE.HISTORY.DESCRIPTION')"
        >
          <p v-if="!topupRequests.length" class="px-5 text-sm text-n-slate-11">
            {{ t('WHATSAPP_USAGE.HISTORY.EMPTY') }}
          </p>
          <table v-else class="w-full">
            <thead>
              <tr
                class="text-left text-xs text-n-slate-10 uppercase tracking-wider"
              >
                <th class="px-5 pb-2 font-medium">
                  {{ t('WHATSAPP_USAGE.HISTORY.DATE') }}
                </th>
                <th class="px-5 pb-2 font-medium">
                  {{ t('WHATSAPP_USAGE.HISTORY.CREDITS') }}
                </th>
                <th class="px-5 pb-2 font-medium">
                  {{ t('WHATSAPP_USAGE.HISTORY.STATUS') }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="request in topupRequests"
                :key="request.id"
                class="border-t border-n-weak"
              >
                <td class="px-5 py-2 text-sm text-n-slate-12">
                  {{ formatDate(request.created_at) }}
                </td>
                <td class="px-5 py-2 text-sm text-n-slate-12">
                  +{{ request.credits.toLocaleString() }}
                </td>
                <td class="px-5 py-2">
                  <span
                    class="inline-flex items-center h-6 px-2 rounded-md text-xs font-medium whitespace-nowrap"
                    :class="statusBadgeClass(request.status)"
                  >
                    {{ t(`WHATSAPP_USAGE.HISTORY.STATUSES.${request.status}`) }}
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </BillingCard>
      </section>
    </template>
  </SettingsLayout>
</template>
