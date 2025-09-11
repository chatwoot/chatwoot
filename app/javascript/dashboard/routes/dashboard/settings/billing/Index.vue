<script setup>
import { useAlert } from 'dashboard/composables';
import { computed, onMounted, ref, h, nextTick, useTemplateRef } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import {
  useMapGetter,
  useStore,
} from 'dashboard/composables/store';

import Payment from './components/Payment.vue';
import Topup from './components/Topup.vue';
import StatusBadge from './components/StatusBadge.vue';

// helpers
import { formatUnixDate, toUnixTimestamp } from 'shared/helpers/DateHelper';

// components
import Table from 'dashboard/components/table/Table.vue';
import WootButton from 'dashboard/components/ui/WootButton.vue';
import WootModal from 'dashboard/components/Modal.vue';
import Modal2 from 'dashboard/components/Modal2.vue';

import {
  useVueTable,
  createColumnHelper,
  getCoreRowModel,
} from '@tanstack/vue-table';

import { getPlanIcon } from './billing-icon-utils'
import { calculatePackagePrice, durationMap } from './pricing-utils'
import { useAccount } from 'dashboard/composables/useAccount';

const { pageIndex } = defineProps({
  pageIndex: {
    type: Number,
    default: 0,
  },
});
const store = useStore();
const { t, locale } = useI18n();

// const { accountId } = useAccount();
// const getAccount = getters['accounts/getAccount']

const loading = ref({});
const showPaymentPopup = ref(false);
const showTopupPopup = ref(false);
const paymentAPI = ref({ message: '' });
const topupType = ref(null);

const currentPackage = ref({});
const plans = ref([]);
const activeSubscription = computed(() => store.state.billing.billing.latestSubscription)
const isSubscriptionActive = computed(() => activeSubscription.value ? activeSubscription.value.status === 'active' : undefined)
const subscriptionHistories = ref([]);
const planIcon = computed(() => {
  const planName = activeSubscription.value?.plan_name?.toString()
  return getPlanIcon(planName)
})


const route = useRoute();
const router = useRouter();


const openTopupPopup = (type) => {
  showTopupPopup.value = true;
  topupType.value = type;
};

const hideTopupPopup = () => {
  showTopupPopup.value = false;
  topupType.value = null;
};

const openPaymentPopup = plan => {
  showPaymentPopup.value = true;
  currentPackage.value = {
    subsDuration: durationMap[selectedTab.value || 'halfyear'],
    ...plan,
  };
};
const hidePaymentPopup = () => {
  showPaymentPopup.value = false;
};

onMounted(async () => {
  if (route.query.expired === 'true') {
    nextTick(() => {
      useAlert(t('BILLING.SUBSCRIPTION_EXPIRED'));

      const newQuery = { ...route.query };
      delete newQuery.expired;

      router.replace({
        path: route.path,
        query: newQuery,
      });
    });
  }

  try {
    const response = await fetch('/api/v1/subscriptions/plans');
    const data = await response.json();
    plans.value = data;
  } catch (error) {
    console.error('Gagal mengambil data pricing:', error);
  }

  (async () => {
    try {
      await store.dispatch('getLatestSubscription')
    } catch (error) {
      console.error('Gagal mengambil data active subscription:', error);
    }
  })()

  try {
    const response = await store.dispatch('subscriptionHistories');
    subscriptionHistories.value = response;
  } catch (error) {
    console.error('Gagal mengambil data subscription histories:', error);
  }
});

const transactionPayment = paymentUrl => {
  if (paymentUrl) {
    window.open(paymentUrl, '_blank');
  }
};

// TABLE RECENT HISTORIES
const renderTableHeader = labelKey =>
  h(
    'div',
    { class: 'text-xs bg-gray-50 px-2 py-1' },
    h('span', { class: 'font-medium' }, t(labelKey))
  );

const tableData = computed(() => {
  return subscriptionHistories.value.map(transaction => {
    const subscriptionStartDate = transaction.subscriptions && transaction.subscriptions[0]?.starts_at ? formatUnixDate(toUnixTimestamp(transaction.subscriptions[0]?.starts_at), 'd MMMM yyyy', locale.value) : '-';
    const subscriptionEndDate = transaction.subscriptions && transaction.subscriptions[0]?.ends_at ? formatUnixDate(toUnixTimestamp(transaction.subscriptions[0]?.ends_at), 'd MMMM yyyy', locale.value) : '-';
    return {
      ...transaction,
      transactionId: transaction.transaction_id,
      package: transaction.package_name,
      duration: t('BILLING.COL_SUBS_DURATION', {
        duration: transaction.duration,
      }),
      status: transaction.status_payment,
      transactionDate: formatUnixDate(
        toUnixTimestamp(transaction.transaction_date),
        'd MMMM yyyy',
        locale.value
      ),
      subscriptionStartDate: subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate,
      paymentUrl: transaction.payment_url,
      id: transaction.id,
    }
  });
});

const defaultSpanRender = cellProps =>
  h(
    'span',
    {
      class: `${(cellProps.getValue()
        ? 'text-[#000000] dark:text-[#ffffff]'
        : 'text-[#000000] dark:text-[#ffffff]')} ${cellProps.column.id === 'transactionId' ? 'cursor-pointer underline' : ''}`,
      onClick: () => {
        if (cellProps.column.id === 'transactionId') {
          showInvoicePopup.value = true
          invoiceData.value = cellProps.row.original
        }
      },
    },
    cellProps.getValue() ? cellProps.getValue() : '---',
  );

const columnHelper = createColumnHelper();

const columns = [
  columnHelper.accessor('transactionId', {
    header: () => renderTableHeader('BILLING.TABLE.HEADER.ID'),
    width: 100,
    cell: defaultSpanRender,
  }),
  columnHelper.accessor('package', {
    header: () => renderTableHeader('BILLING.TABLE.HEADER.PACKAGE'),
    width: 100,
    cell: defaultSpanRender,
  }),
  columnHelper.accessor('duration', {
    header: () => renderTableHeader('BILLING.TABLE.HEADER.DURATION'),
    width: 100,
    cell: defaultSpanRender,
  }),
  // columnHelper.accessor('transactionDate', {
  //  header: () => renderTableHeader('BILLING.TABLE.HEADER.TRANSACTION_DATE'),
  //  width: 150,
  //  cell: defaultSpanRender,
  // }),
  columnHelper.accessor('status', {
    header: () => renderTableHeader('BILLING.TABLE.HEADER.STATUS'),
    width: 100,
    cell: c => {
      return h(StatusBadge, {
        data: c.getValue(),
      })
    },
  }),
  columnHelper.accessor('transactionDate', {
    header: ({ column }) => {
      return h(
        'span',
        { class: 'text-xs font-medium' },
        t('BILLING.TABLE.HEADER.TRANSACTION_DATE')
      );
    },
    width: 150,
    cell: defaultSpanRender,
  }),
  columnHelper.accessor('subscriptionStartDate', {
    header: ({ column }) => {
      return h(
        'span',
        { class: 'text-xs font-medium' },
        t('BILLING.TABLE.HEADER.SUBSCRIPTION_START')
      );
    },
    width: 150,
    cell: defaultSpanRender,
  }),
  columnHelper.accessor('subscriptionEndDate', {
    header: ({ column }) => {
      return h(
        'span',
        { class: 'text-xs font-medium' },
        t('BILLING.TABLE.HEADER.SUBSCRIPTION_END')
      );
    },
    width: 150,
    cell: defaultSpanRender,
  }),
  columnHelper.accessor('paymentUrl', {
    header: () => renderTableHeader('BILLING.TABLE.HEADER.ACTION'),
    width: 100,
    cell: cellProps => {
      const { paymentUrl, status } = cellProps.row.original;
      if (status.toLowerCase() === 'pending') {
        return h(
          WootButton,
          {
            variant: 'primary',
            size: 'small',
            class:
              'bg-yellow-500 hover:bg-yellow-600 text-white rounded-md py-1 px-3 text-xs',
            onClick: () => transactionPayment(paymentUrl),
          },
          { default: () => 'Pay' }
        );
      }
      return null;
    },
  }),
];

const paginationParams = computed(() => {
  return {
    pageIndex: pageIndex,
    pageSize: 10,
  };
});

const table = useVueTable({
  get data() {
    return tableData.value;
  },
  columns,
  manualPagination: true,
  enableSorting: false,
  getCoreRowModel: getCoreRowModel(),
  get rowCount() {
    return subscriptionHistories.value.length || 0;
  },
  state: {
    get pagination() {
      return paginationParams.value;
    },
  },
  onPaginationChange: updater => {
    const newPagination = updater(paginationParams.value);
    emit('pageChange', newPagination.pageIndex);
  },
});

// TAB PRICING & PACKAGES
// Reactive state
const selectedTab = ref('quarterly');
const qty = ref(3);

// Billing cycle tabs data
const billingCycleTabs = computed(() => {
  return [
    { id: 'monthly', name: t('BILLING.MONTHLY'), qty: 1 },
    { id: 'quarterly', name: t('BILLING["3_MONTHS"]'), qty: 3 },
    {
      id: 'halfyear',
      name: t('BILLING["6_MONTHS"]'),
      qty: 6,
      badge: '',
    },
    { id: 'yearly', name: t('BILLING.YEARLY'), qty: 12, badge: '' },
  ]
});

const menuTabs = computed(() => {
  return [
    { id: 'billing', name: t('BILLING.TAB_PAYMENT') },
    { id: 'history', name: t('BILLING.TAB_HISTORY_PAYMENT') },
  ]
});
const selectedMenuTab = ref(menuTabs.value[0].id)

// Pricing plans data
const plansMock = [
  {
    id: 'pro',
    title: 'Pro',
    price: '2.895.000',
    features: [
      '1000 Monthly Active Users',
      '2 Human Agents',
      'Unlimited AI Agents',
      'Unlimited Connected Platforms',
      '5.000 AI Responses',
      'Cekat.AI Advanced AI Models',
    ],
  },
  {
    id: 'business',
    title: 'Business',
    price: '7.495.000',
    features: [
      '5.000 Monthly Active Users',
      '5 Human Agents',
      'Unlimited AI Agents',
      'Unlimited Connected Platforms',
      '25.000 AI Responses',
      'Cekat.AI Advanced AI Models',
    ],
  },
  {
    id: 'enterprise',
    title: 'Enterprise',
    price: '28.995.000',
    features: [
      '30.000 Monthly Active Users',
      '10 Human Agents',
      'Unlimited AI Agents',
      'Unlimited Connected Platforms',
      '150.000 AI Responses',
      'Cekat.AI Advanced AI Models',
    ],
  },
  {
    id: 'unlimited',
    title: 'Unlimited',
    price: '78.995.000',
    features: [
      'Unlimited Monthly Active Users',
      'Unlimited Human Agents',
      'Unlimited AI Agents',
      'Unlimited Connected Platforms',
      '500.000 AI Responses',
      'Cekat.AI Advanced AI Models + Exclusive AI Models',
    ],
  },
];
// END TAB PRICING & PACKAGES

const selectedTabDisplay = computed(() => {
  const tab = selectedTab.value
  return t(`BILLING.TAB_DISPLAY.${tab}`)
})

const showInvoicePopup = ref(false)
const invoiceData = ref(undefined)

const packageSectionRef = useTemplateRef('packageSection')

function scrollToPackage() {
  selectedMenuTab.value = 'billing'
  nextTick(() => {
    packageSectionRef.value.scrollIntoView({
      behavior: 'smooth',
    })
  })
}
</script>

<template>
  <woot-modal v-model:show="showPaymentPopup" :on-close="hidePaymentPopup">
    <Payment :id="currentPackage.id" :name="currentPackage.name" :plan="currentPackage" :plans="plans"
      :duration="selectedTab" :qty="qty" :billing-cycle-tabs="billingCycleTabs" @close="hidePaymentPopup" />
  </woot-modal>

  <woot-modal v-model:show="showTopupPopup" :on-close="hideTopupPopup">
    <Topup :id="activeSubscription.id" :topup-type="topupType" @close="hideTopupPopup" />
  </woot-modal>

  <Modal2 v-model:show="showInvoicePopup" :on-close="() => {
    showInvoicePopup = false
  }">
    <InvoiceModal :data="invoiceData" />
  </Modal2>

  <div class="billing-page p-4 w-full">
    <div
      class="bg-white dark:!bg-[#1D1E24] border border-[#0000001A] rounded-lg p-5 flex flex-col gap-4 mb-8"
      v-if="activeSubscription">
      <div class="flex flex-col lg:flex-row">
        <div class="flex-1">
          <span class="font-bold !text-black-700 dark:!text-white">{{ $t('PAYMENT.STATUS_SUBS') }}</span>
        </div>
        <div>
          <span class="text-sm italic dark:text-[#E0E1E6]">
            <span v-html="$t('PAYMENT.RESET_LABEL')"></span>
          </span>
        </div>
      </div>
      <div class="flex flex-col gap-2 lg:flex-row lg:items-center">
        <div class="flex-1 min-w-0 flex flex-row gap-3 items-center">
          <div class="h-16 w-16 rounded-lg bg-[#D9EFC4] flex justify-center items-center p-1">
            <img v-if="planIcon" :src="planIcon">
          </div>
          <div class="flex flex-col flex-1 min-w-0">
            <div class="flex flex-row gap-2">
              <span class="text-[#2F9428] font-bold text-lg">{{ activeSubscription?.plan_name ?? 'N/A' }}</span>
              <div v-if="isSubscriptionActive && !isSubscriptionActive" class="py-1 px-2 text-sm bg-red-400 rounded text-white">
                <span>{{ $t('PAYMENT.EXPIRED_LABEL') }}</span>
                <span class="underline cursor-pointer" @click="scrollToPackage">
                  {{ $t('PAYMENT.EXPIRED_LABEL_BUY_NOW') }}
                </span>
              </div>
            </div>
            <div class="flex flex-col mt-1">
              <span class="text-xs dark:text-[#E0E1E6]">{{ $t('PAYMENT.SUBS_ACTIVE_UNTIL') }}</span>
              <span class="text-sm font-bold text-[#2F9428]">{{
                activeSubscription?.ends_at
                ? formatDate(activeSubscription?.ends_at)
                : 'N/A'
                }}</span>
            </div>
          </div>
        </div>
        <div class="flex flex-row gap-5">
          <div class="w-[2px] bg-[#CDD8CD] dark:bg-[#373943] rounded"></div>
          <div class="flex flex-col gap-2">
            <span class="text-xs dark:text-[#E0E1E6]">{{ $t('PAYMENT.TOTAL_MAU_LABEL') }}</span>
            <div class="flex flex-row gap-3">
              <div class="rounded-lg bg-[#DDEBDD] px-3 py-[4px]">
                <span>
                  <span class="font-bold text-2xl text-[#2C4D3D]">{{ activeSubscription?.subscription_usage?.mau_count
                    }}</span>
                  <span class="dark:text-[#5A6169]"> /{{ activeSubscription?.max_mau }}</span>
                  <span v-if="activeSubscription?.additional_mau"
                    class="text-[#2F9428] font-bold"> +{{ activeSubscription?.additional_mau
                    }}</span>
                </span>
              </div>
              <div
                class="border border-[#377832] rounded-lg bg-gradient-to-t from-[#4D8F48] to-[#57A852] flex items-center justify-center p-2 cursor-pointer"
                @click="openTopupPopup('max_active_users')">
                <img src="~dashboard/assets/images/payment/ic_total_user.svg">
              </div>
            </div>
          </div>
          <div class="w-[2px] bg-[#CDD8CD] dark:bg-[#373943] rounded"></div>
          <div class="flex flex-col gap-2">
            <span class="text-xs dark:text-[#E0E1E6]">{{ $t('PAYMENT.TOTAL_AI_RESPONSE_LABEL') }}</span>
            <div class="flex flex-row gap-3">
              <div class="rounded-lg bg-[#EFEEC5] px-3 py-[4px]">
                <span>
                  <span class="font-bold text-2xl text-[#4D422C]">{{
                    activeSubscription?.subscription_usage?.ai_responses_count }}</span>
                  <span class="dark:text-[#5A6169]"> /{{ activeSubscription?.max_ai_responses }}</span>
                  <span v-if="activeSubscription?.additional_ai_responses"
                    class="text-[#2F9428] font-bold"> +{{
                    activeSubscription?.additional_ai_responses }}</span>
                </span>
              </div>
              <div
                class="border border-[#99601D] rounded-lg bg-gradient-to-t from-[#BE7625] to-[#F8AB40] flex items-center justify-center p-2 cursor-pointer"
                @click="openTopupPopup('ai_responses')">
                <img src="~dashboard/assets/images/payment/ic_total_answer.svg">
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Ramadan Special Package -->
    <div v-if="specialPromo" class="mb-6 border border-gray-300 rounded-lg relative overflow-hidden">
      <!-- Ribbon -->
      <div
        class="absolute top-0 right-0 bg-gradient-to-r from-yellow-500 to-yellow-600 text-white transform rotate-45 translate-x-8 translate-y-2 py-1 px-8 text-xs font-bold">
        POPULER
      </div>

      <div class="p-5">
        <div class="flex flex-wrap md:flex-nowrap">
          <!-- Left Side with Gift Icon -->
          <div class="w-full md:w-auto flex justify-center md:justify-start md:mr-4">
            <div class="w-16 h-16 flex items-center justify-center bg-gray-200 rounded-full">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none"
                stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                class="text-blue-500">
                <rect x="3" y="8" width="18" height="4" rx="1" />
                <path d="M12 8v13" />
                <path d="M19 12v7a2 2 0 01-2 2H7a2 2 0 01-2-2v-7" />
                <path d="M7.5 8a2.5 2.5 0 100-5 2.5 2.5 0 000 5z" />
                <path d="M16.5 8a2.5 2.5 0 100-5 2.5 2.5 0 000 5z" />
                <path d="M12 8H7.5C6.12 8 5 6.88 5 5.5 5 4.12 6.12 3 7.5 3h0a2.5 2.5 0 014.5 2v3" />
                <path d="M12 8h4.5C17.88 8 19 6.88 19 5.5 19 4.12 17.88 3 16.5 3h0a2.5 2.5 0 00-4.5 2v3" />
              </svg>
            </div>
          </div>

          <!-- Main Content -->
          <div class="w-full">
            <p class="text-sm text-blue-500 font-medium">
              {{ specialPromo.title }}
            </p>
            <h2 class="text-xl text-blue-500 font-medium mb-2">
              {{ specialPromo.name }}
            </h2>

            <div class="flex items-center mb-3">
              <span class="text-xl md:text-2xl font-bold text-blue-600">Rp {{ formatPrice(specialPromo.price) }}</span>
              <span class="text-sm line-through text-gray-500 ml-2">Rp {{ formatPrice(specialPromo.originalPrice)
                }}</span>
              <span class="ml-2 bg-red-500 text-white text-xs px-2 py-0.5 rounded">{{ specialPromo.promoTag }}</span>
            </div>

            <ul class="space-y-2 mb-4">
              <li v-for="(feature, index) in specialPromo.features" :key="index" class="flex items-start">
                <span class="text-gray-700 mr-2">•</span>
                <span v-html="feature" />
              </li>
            </ul>

            <p class="text-sm text-gray-600 mb-4">
              {{ specialPromo.description }}
            </p>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              <!-- Left Benefits -->
              <div>
                <h4 class="font-medium mb-2">Manfaat Utama</h4>
                <ul class="space-y-2">
                  <li v-for="(benefit, index) in specialPromo.mainBenefits" :key="index" class="flex items-start">
                    <span class="text-blue-500 mr-2">
                      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none"
                        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10" />
                        <path d="M8 14s1.5 2 4 2 4-2 4-2" />
                        <line x1="9" y1="9" x2="9.01" y2="9" />
                        <line x1="15" y1="9" x2="15.01" y2="9" />
                      </svg>
                    </span>
                    <div>
                      <p class="font-medium">{{ benefit.title }}</p>
                      <p class="text-sm text-gray-600">
                        {{ benefit.description }}
                      </p>
                    </div>
                  </li>
                </ul>
              </div>

              <!-- Right Benefits -->
              <div>
                <h4 class="font-medium mb-2">Bonus Eksklusif</h4>
                <ul class="space-y-2">
                  <li v-for="(bonus, index) in specialPromo.exclusiveBonuses" :key="index" class="flex items-start">
                    <span class="text-green-500 mr-2">
                      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none"
                        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M22 11.08V12a10 10 0 11-5.93-9.14" />
                        <polyline points="22 4 12 14.01 9 11.01" />
                      </svg>
                    </span>
                    <div>
                      <p class="font-medium">{{ bonus.title }}</p>
                      <p class="text-sm text-gray-600">
                        {{ bonus.description }}
                      </p>
                    </div>
                  </li>
                </ul>
              </div>
            </div>

            <div class="text-center bg-red-100 p-2 rounded text-sm mb-4">
              {{ specialPromo.limitedOffer }}
            </div>

            <div class="text-center">
              <button
                class="bg-blue-500 hover:bg-blue-600 text-white font-medium py-2 px-6 rounded-full inline-flex items-center"
                @click="purchaseSpecialPromo">
                {{ specialPromo.ctaText }}
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none"
                  stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="ml-1">
                  <line x1="5" y1="12" x2="19" y2="12" />
                  <polyline points="12 5 19 12 12 19" />
                </svg>
              </button>
              <p class="text-sm text-gray-600 mt-2">
                {{ specialPromo.guaranteeText }}
              </p>
              <p class="text-xs text-gray-500 mt-1">
                {{ specialPromo.contactInfo }}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div ref="packageSection">
      <div class="border-b-4"
        :class="[{
          'border-[#52964D]': selectedMenuTab === 'billing',
          'border-[#D78D30]': selectedMenuTab === 'history',
        }]">
        <div class="flex flex-row justify-center">
          <button v-for="tab in menuTabs" :key="tab.id"
            class="px-5 py-3 rounded-b-none rounded-t-xl font-normal dark:bg-[#1D1E24]"
            :class="[{
              '!font-bold text-[#FDFDFD]': selectedMenuTab === tab.id,
              '!bg-[#52964D]': selectedMenuTab === tab.id && selectedMenuTab == 'billing',
              '!bg-[#D78D30]': selectedMenuTab === tab.id && selectedMenuTab == 'history',
             }]" @click="selectedMenuTab = tab.id">
            {{ tab.name }}
          </button>
        </div>
      </div>

      <div class="bg-gradient-to-t from-[#F0F5F0] to-white dark:from-[#1D1E24] dark:to-[#1D1E24] border !border-t-0 border-[#0000001A] rounded-b-lg p-5">
        <!-- Platform & Duration Tabs -->
        <div v-if="selectedMenuTab === 'billing'" class="pricing-container">
          <!-- Tabs Navigation -->
          <div class="billing-cycle-tabs">
            <div class="tabs-wrapper bg-[#E9F5EC] dark:bg-[#23252E]">
              <button v-for="tab in billingCycleTabs" :key="tab.id" class="tab-button text-[#475569] dark:text-[#E0E1E6]"
                :class="[{ active: selectedTab === tab.id }]" @click="selectedTab = tab.id">
                {{ tab.name }}
                <span v-if="tab.badge" class="tab-badge">{{ tab.badge }}</span>
              </button>
            </div>
          </div>

          <!-- Pricing Plans -->
          <div class="pricing-plans">
            <div v-for="plan in plans" :key="plan.id" class="pricing-card bg-[#fff] dark:bg-[#23252d]">
              <div class="plan-header flex flex-row">
                <div class="flex-1">
                  <h3 class="plan-title text-[#475569] dark:text-[#E0E1E6] min-h-[100px]">{{ $t(`BILLING.PLAN_NAME.${plan.name.toLowerCase()}`) }}</h3>
                </div>
                <div class="h-16 w-16 rounded-lg bg-[#D9EFC4] flex justify-center items-center mt-[-44px] p-1">
                  <img :src="getPlanIcon(plan.name)">
                </div>
              </div>

              <div class="plan-price text-[#475569] dark:text-[#E0E1E6]">
                <div class="price">
                  {{ formatPrice(calculatePackagePrice(plan.monthly_price, plan.name, selectedTab)) }}
                </div>
                <div class="price-period">
                  IDR /{{ durationMap[selectedTab] == 1 ? t('BILLING.TAB_DISPLAY.qty_month') : `${durationMap[selectedTab]} ${t('BILLING.TAB_DISPLAY.qty_month')}` }}
                </div>
                <div class="package-type">{{ selectedTabDisplay }}</div>
              </div>

              <div class="plan-features text-[#475569] dark:text-[#E0E1E6]">
                <h4 class="text-[#475569] dark:text-[#E0E1E6]">{{ $t(`BILLING.FEATURE.${plan.name.toLowerCase()}`) }}</h4>

                <ul class="feature-list">
                  <li v-for="(feature, index) in plan.features" :key="index" class="feature-item">
                    <span class="icon-check" />
                    <span class="feature-text text-[#475569] dark:text-[#E0E1E6]">{{ $t(`BILLING.${feature.replaceAll('.', '')}`) }}</span>
                  </li>
                </ul>
              </div>

              <button class="button-primary buy-button" @click="openPaymentPopup(plan)">
                {{ t('BILLING.BTN_BUY') }}
              </button>
            </div>
          </div>
        </div>

        <!-- Recent Transactions Section -->
        <div v-else-if="selectedMenuTab === 'history'" class="flex flex-col flex-wrap self-center overflow-x-auto h-[500px]">
          <div>
            <div>
              <div>
                <Table :table="table" class="min-w-full divide-y divide-gray-200" />

                <div v-show="!tableData.length"
                  class="h-48 flex items-center justify-center text-n-slate-12 text-sm flex-col">
                  <!-- <chatwoot-icon name="currency-dollar" size="medium" class="mb-2 text-slate-400"></chatwoot-icon> -->
                  <p>{{ $t('BILLING.NO_TRANSACTIONS') }}</p>
                </div>

                <!-- <div v-if="metrics?.totalTransactionCount" class="table-pagination">
                  <Pagination class="mt-2" :table="table" />
                </div> -->
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState, mapActions } from 'vuex';
import InvoiceModal from './components/InvoiceModal.vue';
import billingApi from '../../../../api/billing';

export default {
  name: 'BillingPage',
  data() {
    return {
      loading: true,
      error: null,
      planDetails: {
        name: 'FREE',
        expiryDate: '2025-04-15',
      },
      usage: {
        activeUsers: 0,
        additionalMau: 0,
        resetDate: 1,
        aiResponses: {
          used: 0,
          limit: 2000,
        },
        additionalResponses: 0,
      },
      specialPromo: null,
      selectedPlatform: 'ai',
      selectedDuration: '3mo',
      platformOptions: [
        { id: 'ai', name: 'AI Platform' },
        { id: 'crm', name: 'CRM Only (Lite)' },
      ],
      durationOptions: [
        { id: 'monthly', name: 'Bulanan' },
        { id: '3mo', name: '3 Bulan' },
        { id: 'halfyearly', name: 'Setengah Tahun' },
        { id: 'yearly', name: "Tahunan" },
      ],
      durationPromos: {
        '3mo': '1 Month Free!',
        halfyearly: '2 Months Free!',
        yearly: '3 Bulan Free!',
      },
      // plans: [],
      transactions: [],
    };
  },
  computed: {
    ...mapState({
      subscription: state => state.billing.myActiveSubscription,
      // subscriptionHistories: state => state.billing.subscriptionHistories,
      isFetching: state => state.uiFlags.isFetching,
    }),
    filteredPlans() {
      return this.plans.filter(
        plan =>
          plan.platformType === this.selectedPlatform &&
          plan.durationType === this.selectedDuration
      );
    },
  },
  methods: {
    ...mapActions(['myActiveSubscription', 'subscriptionHistories']),
    async fetchData() {
      try {
        // this.loading = true;

        // Fetch current plan details
        // try {
        //   await this.$store.dispatch('myActiveSubscription');
        // } catch (error) {
        //   alertMessage =
        //     parseAPIErrorResponse(error) ||
        //     // this.$t('RESET_PASSWORD.API.ERROR_MESSAGE');
        // }

        const planResponse = await this.apiGet('/api/billing/current-plan');
        this.planDetails = planResponse.data;

        // Fetch usage statistics
        const usageResponse = await this.apiGet('/api/billing/usage');
        this.usage = usageResponse.data;

        // Fetch special promotions
        // const promoResponse = await this.apiGet('/api/billing/special-promos');
        // this.specialPromo = promoResponse.data.active ? promoResponse.data : null;

        // Fetch available plans
        // const plansResponse = await this.apiGet('/api/billing/plans');
        // this.plans = plansResponse.data;

        // Fetch recent transactions
        const transactionsResponse = await this.apiGet(
          '/api/billing/transactions'
        );
        this.transactions = transactionsResponse.data;
      } catch (error) {
        this.error = 'Failed to load billing data';
        console.error('Error fetching billing data:', error);
      } finally {
        // this.loading = false;
      }
    },

    // API request helpers
    async apiGet(url) {
      // Mock API call - replace with actual axios call
      return this.getMockData(url);
    },

    async apiPost(url, data) {
      // Mock API post - replace with actual axios call
      console.log('API POST', url, data);
      return { success: true };
    },

    // Mock data for demonstration
    getMockData(url) {
      const mockResponses = {
        '/api/billing/current-plan': {
          data: {
            name: 'FREE',
            expiryDate: '2025-04-15',
          },
        },
        '/api/billing/usage': {
          data: {
            activeUsers: 0,
            additionalMau: 0,
            resetDate: 1,
            aiResponses: {
              used: 0,
              limit: 2000,
            },
            additionalResponses: 0,
          },
        },
        '/api/billing/special-promos': {
          data: {
            active: true,
            title: 'Paket Special Ramadan',
            name: 'Paket Ramadan "Terima Beres"',
            price: 4497000,
            originalPrice: 8997000,
            promoTag: 'LIMITED TIME',
            features: [
              'Setup AI dan Flows dengan Prompt Specialist - <span class="text-gray-700">Rp 4.000.000</span> - <span class="text-blue-500 font-medium">FREE</span>',
              'WhatsApp Anti Banned - <span class="text-gray-700">Rp 500.000</span> - <span class="text-blue-500 font-medium">FREE</span>',
              'Early Akses dan 1-on-1 Training fitur Flows, Ticketing, dan Advanced AI mode',
            ],
            description:
              'Scale up penjualan dan tetap layani pelanggan di Bulan Ramadan ini! Selesaikan dalam sekali dan biarkan AIUI Prompt kami membuat AI untuk anda "Terima beres"',
            mainBenefits: [
              {
                title: 'Paket Cepat/i Business 3 bulan',
                description: 'Layanan AI otomatis untuk bisnis Anda',
              },
              {
                title: 'Setup Lengkap oleh Tim AIUI',
                description: 'Anda tinggal terima beres, semua diatur',
              },
              {
                title: 'Konsultasi Pribadi dengan AIUI Prompt',
                description: 'Optimalisasi AI Anda dengan pakar kami',
              },
            ],
            exclusiveBonuses: [
              {
                title: 'Akses Model AI & Fitur Flows Terbaru',
                description: 'Gunakan teknologi AI paling canggih',
              },
              {
                title: 'Fitur Anti-Banned WhatsApp',
                description: 'Jaga akun WhatsApp Anda tetap aman',
              },
              {
                title: 'Dukungan Prioritas 24 Jam',
                description: 'Bantuan cepat kapanpun Anda butuhkan',
              },
            ],
            limitedOffer: 'Promo Terbatas - Hanya 100 Slot!',
            ctaText: 'Dapatkan Paket Ramadan Sekarang',
            guaranteeText: 'Garansi Uang Kembali 7 Hari Jika Anda Tidak Puas',
            contactInfo:
              'Promo khusus Ramadan saja. Anda akan di-contact oleh tim kami setelah pembelian.',
          },
        },
        '/api/billing/plans': {
          data: [
            {
              id: 'pro-ai-3mo',
              name: 'Pro',
              price: 1737000,
              platformType: 'ai',
              durationType: '3mo',
              packageType: 'Paket Per 3 Bulan',
              features: [
                '1000 Monthly Active Users',
                '2 Human Agents',
                'Unlimited AI Agents',
                'Unlimited Connected Platforms',
                '5,000 AI Responses',
                'Cakat.AI Advanced AI Models',
              ],
            },
            {
              id: 'business-ai-3mo',
              name: 'Business',
              price: 4497000,
              platformType: 'ai',
              durationType: '3mo',
              packageType: 'Paket Per 3 Bulan',
              features: [
                '5,000 Monthly Active Users',
                '5 Human Agents',
                'Unlimited AI Agents',
                'Unlimited Connected Platforms',
                '25,000 AI Responses',
                'Cakat.AI Advanced AI Models',
              ],
            },
            {
              id: 'enterprise-ai-3mo',
              name: 'Enterprise',
              price: 17397000,
              platformType: 'ai',
              durationType: '3mo',
              packageType: 'Paket Per 3 Bulan',
              features: [
                '10,000 Monthly Active Users',
                '10 Human Agents',
                'Unlimited AI Agents',
                'Unlimited Connected Platforms',
                '150,000 AI Responses',
                'Cakat.AI Advanced AI Models',
              ],
            },
            {
              id: 'unlimited-ai-3mo',
              name: 'Unlimited',
              price: 47397000,
              platformType: 'ai',
              durationType: '3mo',
              packageType: 'Paket Per 3 Bulan',
              features: [
                'Unlimited Monthly Active Users',
                'Unlimited Human Agents',
                'Unlimited AI Agents',
                'Unlimited Connected Platforms',
                '500,000 AI Responses',
                'Cakat.AI Advanced AI Models + Exclusive AI Models',
              ],
            },
          ],
        },
        '/api/billing/transactions': {
          data: [],
        },
      };

      return Promise.resolve(mockResponses[url] || { data: [] });
    },

    // Utility methods
    formatDate(dateString) {
      const date = new Date(dateString);
      return new Intl.DateTimeFormat(this.$root.$i18n.locale || 'id-ID', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
      }).format(date);
    },

    formatPrice(price) {
      return price.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.');
    },

    formattedPrice(value) {
      if (value >= 1000) {
        return Math.round(value / 1000).toLocaleString('id-ID') + 'K'; // Gunakan toLocaleString untuk menambahkan titik
      }
      return value.toLocaleString('id-ID'); // Format angka kecil dengan titik juga
    },

    getDurationLabel(durationId) {
      switch (durationId) {
        case 'monthly':
          return '1mo';
        case '3mo':
          return '3mo';
        case 'halfyearly':
          return '6mo';
        case 'yearly':
          return '12mo';
        default:
          return durationId;
      }
    },

    getDurationPromo(durationId) {
      return this.durationPromos[durationId] || null;
    },

    // Action methods
    changePlatform(platformId) {
      this.selectedPlatform = platformId;
    },

    changeDuration(durationId) {
      this.selectedDuration = durationId;
    },

    async topUpMau() {
      try {
        await this.apiPost('/api/billing/topup-mau', {});
        // Handle success - perhaps show a modal or navigate to checkout
      } catch (error) {
        console.error('Error topping up MAU:', error);
      }
    },

    async topUpResponses() {
      try {
        await this.apiPost('/api/billing/topup-responses', {});
        // Handle success
        alert('Redirecting to AI responses top-up page...');
      } catch (error) {
        console.error('Error topping up responses:', error);
      }
    },

    async purchaseSpecialPromo() {
      try {
        await this.apiPost('/api/billing/purchase-promo', {
          promoId: 'ramadan-special',
        });
        // Handle success
        alert('Redirecting to checkout for Ramadan Special package...');
      } catch (error) {
        console.error('Error purchasing promo:', error);
      }
    },

    async purchasePlan(planId) {
      try {
        await this.apiPost('/api/billing/purchase-plan', { planId });
        // Handle success
        alert(`Redirecting to checkout for plan: ${planId}...`);
      } catch (error) {
        console.error('Error purchasing plan:', error);
      }
    },
  },
  async created() {
    // try {
    //   const response = await fetch('/api/v1/subscriptions/plans');
    //   const data = await response.json();
    //   this.plans = data;
    // } catch (error) {
    //   console.error('Gagal mengambil data pricing:', error);
    // }
  },
  mounted() {
    // this.myActiveSubscription();
    // this.$store.dispatch('myActiveSubscription');
    // this.$store.dispatch('subscriptionHistories');
    this.fetchData();
  },
};
</script>

<style scoped>
/* TAB PRICING & PAKCAGES */
.pricing-container {
  max-width: 1200px;
  font-family:
    system-ui,
    -apple-system,
    BlinkMacSystemFont,
    'Segoe UI',
    Roboto,
    Oxygen,
    Ubuntu,
    Cantarell,
    'Open Sans',
    'Helvetica Neue',
    sans-serif;
}

/* Tabs styling */
.billing-cycle-tabs {
  margin-bottom: 2rem;
  display: flex;
  justify-content: center;
}

.tabs-wrapper {
  display: flex;
  border-radius: 50px;
  padding: 5px 10px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.tab-button {
  padding: 0.7rem 1.5rem;
  border: none;
  background: transparent;
  cursor: pointer;
  font-size: 0.875rem;
  font-weight: 500;
  border-radius: 50px;
  position: relative;
  transition: all 0.2s ease;
}

.tab-button.active {
  background-color: #389946;
  color: white;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
}

.tab-badge {
  position: absolute;
  top: -8px;
  right: -8px;
  background-color: #1f93ff;
  color: white;
  font-size: 0.6rem;
  padding: 2px 6px;
  border-radius: 1rem;
  font-weight: bold;
}

/* Pricing cards */
.pricing-plans {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
}

.pricing-card {
  border-radius: 0.5rem;
  padding: 1.5rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  display: flex;
  flex-direction: column;
  height: 100%;
}

.plan-header {
  margin-bottom: 1rem;
}

.plan-title {
  font-size: 1.25rem;
  font-weight: 600;
  margin-right: 0.5rem;
}

.plan-price {
  margin-bottom: 1.5rem;
}

.price {
  font-size: 1.75rem;
  font-weight: 700;
}

.price-period {
  font-size: 1rem;
}

.package-type {
  font-size: 0.875rem;
  margin-top: 0.5rem;
}

.plan-features {
  margin-bottom: 1.5rem;
  flex-grow: 1;
}

.plan-features h4 {
  font-size: 1rem;
  font-weight: 600;
  margin-bottom: 1rem;
}

.feature-list {
  list-style: none;
  padding: 0;
}

.feature-item {
  display: flex;
  align-items: flex-start;
  margin-bottom: 0.75rem;
  font-size: 0.875rem;
}

.icon-check {
  width: 1rem;
  height: 1rem;
  background-color: #44ce4b;
  border-radius: 50%;
  margin-right: 0.5rem;
  position: relative;
  flex-shrink: 0;
}

.icon-check::after {
  content: '';
  position: absolute;
  left: 6px;
  top: 4px;
  width: 5px;
  height: 8px;
  border: solid white;
  border-width: 0 2px 2px 0;
  transform: rotate(45deg);
}

.feature-text {
}

.buy-button {
  background-color: #389946;
  color: white;
  border: none;
  border-radius: 0.375rem;
  padding: 0.75rem 1rem;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.2s ease;
  width: 100%;
  margin-top: auto;
}

.buy-button:hover {
  background-color: #389946;
  opacity: 0.7;
}

@media (max-width: 768px) {
  .pricing-plans {
    grid-template-columns: 1fr;
  }

  .tabs-wrapper {
    flex-wrap: wrap;
    justify-content: center;
  }

  .tab-button {
    margin-bottom: 0.5rem;
  }
}

/* ./ END TAB PRICING & PAKCAGES */
.shadow-lg {
  --tw-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1),
    0 4px 6px -4px rgba(0, 0, 0, 0.1);
  --tw-shadow-colored: 0 10px 15px -3px var(--tw-shadow-color),
    0 4px 6px -4px var(--tw-shadow-color);
}

.shadow-inner,
.shadow-lg {
  box-shadow: var(--tw-ring-offset-shadow, 0 0 #0000),
    var(--tw-ring-shadow, 0 0 #0000), var(--tw-shadow);
}

.bg-white {
  --tw-bg-opacity: 1;
  background-color: rgb(255 255 255 / var(--tw-bg-opacity));
}

.border-gray-200 {
  --tw-border-opacity: 1;
  border-color: rgb(229 231 235 / var(--tw-border-opacity));
}

.border {
  border-width: 1px;
}

.rounded-lg {
  border-radius: 0.5rem;
}

.transactions-container {
  margin: 0 auto;
  font-size: 0.75rem;
}

table {
  border-radius: 6px;
  overflow: hidden;
}

.btn-dark {
  --tw-border-opacity: 1;
  --tw-bg-opacity: 1;
  background-color: rgb(59 63 92 / var(--tw-bg-opacity));
  --tw-text-opacity: 1;
  --tw-shadow-color: rgba(59, 63, 92, 0.6);
  --tw-shadow: var(--tw-shadow-colored);
}

.btn {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 0.375rem;
  border-width: 1px;
  padding: 0.5rem 1.25rem;
  font-size: 0.875rem;
  line-height: 1.25rem;
  font-weight: 600;
  --tw-shadow: 0 10px 20px -10px;
  --tw-shadow-colored: 0 10px 20px -10px var(--tw-shadow-color);
  outline: 2px solid transparent;
  outline-offset: 2px;
  transition-property:
    color,
    background-color,
    border-color,
    text-decoration-color,
    fill,
    stroke,
    opacity,
    box-shadow,
    transform,
    filter,
    -webkit-backdrop-filter;
  transition-property: color, background-color, border-color,
    text-decoration-color, fill, stroke, opacity, box-shadow, transform, filter,
    backdrop-filter;
  transition-property:
    color,
    background-color,
    border-color,
    text-decoration-color,
    fill,
    stroke,
    opacity,
    box-shadow,
    transform,
    filter,
    backdrop-filter,
    -webkit-backdrop-filter;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  transition-duration: 0.3s;
}

.billing-page {
  font-family: 'Inter', sans-serif;
}

.bg-gradient-to-r {
  background-image: linear-gradient(to right, var(--tw-gradient-stops));
}

.from-cyan-500 {
  --tw-gradient-from: #06b6d4 var(--tw-gradient-from-position);
  --tw-gradient-to: rgba(6, 182, 212, 0) var(--tw-gradient-to-position);
  --tw-gradient-stops: var(--tw-gradient-from), var(--tw-gradient-to);
}

.to-cyan-400 {
  --tw-gradient-to: #22d3ee var(--tw-gradient-to-position) !important;
}

.to-violet-400 {
  --tw-gradient-to: #a78bfa var(--tw-gradient-to-position) !important;
}

.from-violet-500 {
  --tw-gradient-from: #8b5cf6 var(--tw-gradient-from-position);
  --tw-gradient-to: rgba(139, 92, 246, 0) var(--tw-gradient-to-position);
  --tw-gradient-stops: var(--tw-gradient-from), var(--tw-gradient-to);
}

.to-blue-400 {
  --tw-gradient-to: #60a5fa var(--tw-gradient-to-position) !important;
}

.from-blue-500 {
  --tw-gradient-from: #3b82f6 var(--tw-gradient-from-position);
  --tw-gradient-to: rgba(59, 130, 246, 0) var(--tw-gradient-to-position);
  --tw-gradient-stops: var(--tw-gradient-from), var(--tw-gradient-to);
}

.panel {
  position: relative;
  --tw-bg-opacity: 1;
  background-color: rgb(255 255 255 / var(--tw-bg-opacity));
  --tw-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px -1px rgba(0, 0, 0, 0.1);
  --tw-shadow-colored: 0 1px 3px 0 var(--tw-shadow-color),
    0 1px 2px -1px var(--tw-shadow-color);
  box-shadow: var(--tw-ring-offset-shadow, 0 0 #0000),
    var(--tw-ring-shadow, 0 0 #0000), var(--tw-shadow);
  border-radius: 0.375rem;
  padding: 1.25rem;
}
</style>
