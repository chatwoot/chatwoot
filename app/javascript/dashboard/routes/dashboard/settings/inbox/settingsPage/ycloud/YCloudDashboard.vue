<script>
import YCloudAPI from 'dashboard/api/ycloud';
import { useAlert } from 'dashboard/composables';
import SettingsSection from '../../../../../../components/SettingsSection.vue';

export default {
  components: { SettingsSection },
  props: {
    inbox: { type: Object, default: () => ({}) },
  },
  data() {
    return {
      balance: null,
      businessAccounts: [],
      lastEvents: {},
      isLoading: true,
    };
  },
  computed: {
    providerConfig() {
      return this.inbox.provider_config || {};
    },
    qualityInfo() {
      return this.lastEvents.phone_number_quality_update || {};
    },
    wabaInfo() {
      return this.lastEvents.business_account_update || {};
    },
    callInfo() {
      return this.lastEvents.call_event || {};
    },
    flowInfo() {
      return this.lastEvents.flow_status_change || {};
    },
  },
  mounted() {
    this.fetchData();
  },
  methods: {
    async fetchData() {
      this.isLoading = true;
      this.lastEvents = this.providerConfig.last_events || {};
      try {
        const balanceRes = await YCloudAPI.getBalance(this.inbox.id);
        this.balance = balanceRes.data;
      } catch {
        this.balance = null;
      }
      try {
        const wabaRes = await YCloudAPI.listBusinessAccounts(this.inbox.id);
        this.businessAccounts = wabaRes.data.items || [];
      } catch {
        this.businessAccounts = [];
      }
      this.isLoading = false;
    },
  },
};
</script>

<template>
  <div class="py-4">
    <div v-if="isLoading" class="text-center py-8">
      <span class="spinner" />
      <p>{{ $t('YCLOUD.DASHBOARD.LOADING') }}</p>
    </div>
    <div v-else>
      <!-- Balance Card -->
      <SettingsSection
        :title="$t('YCLOUD.DASHBOARD.BALANCE')"
        :sub-title="$t('YCLOUD.DASHBOARD.BALANCE_DESC')"
      >
        <div v-if="balance" class="flex items-center gap-4 p-4 bg-n-slate-1 rounded-lg">
          <div class="text-3xl font-bold text-n-blue-text">
            {{ balance.currency }} {{ balance.amount }}
          </div>
        </div>
        <div v-else class="p-4 bg-n-slate-1 rounded-lg text-n-slate-11">
          {{ $t('YCLOUD.DASHBOARD.BALANCE_UNAVAILABLE') }}
        </div>
      </SettingsSection>

      <!-- Phone Number Quality -->
      <SettingsSection
        :title="$t('YCLOUD.DASHBOARD.QUALITY')"
        :sub-title="$t('YCLOUD.DASHBOARD.QUALITY_DESC')"
      >
        <div class="grid grid-cols-2 gap-4">
          <div class="p-4 bg-n-slate-1 rounded-lg">
            <p class="text-sm text-n-slate-11">{{ $t('YCLOUD.DASHBOARD.QUALITY_RATING') }}</p>
            <p class="text-lg font-semibold" :class="{
              'text-green-600': qualityInfo.quality_rating === 'GREEN',
              'text-yellow-600': qualityInfo.quality_rating === 'YELLOW',
              'text-red-600': qualityInfo.quality_rating === 'RED',
            }">
              {{ qualityInfo.quality_rating || '—' }}
            </p>
          </div>
          <div class="p-4 bg-n-slate-1 rounded-lg">
            <p class="text-sm text-n-slate-11">{{ $t('YCLOUD.DASHBOARD.MSG_LIMIT') }}</p>
            <p class="text-lg font-semibold">{{ qualityInfo.messaging_limit || '—' }}</p>
          </div>
        </div>
      </SettingsSection>

      <!-- Business Accounts -->
      <SettingsSection
        :title="$t('YCLOUD.DASHBOARD.WABA')"
        :sub-title="$t('YCLOUD.DASHBOARD.WABA_DESC')"
      >
        <div v-if="businessAccounts.length">
          <div
            v-for="waba in businessAccounts"
            :key="waba.id"
            class="p-4 bg-n-slate-1 rounded-lg mb-2"
          >
            <p class="font-semibold">{{ waba.name || waba.id }}</p>
            <p class="text-sm text-n-slate-11">
              ID: {{ waba.id }} | Status: {{ waba.accountReviewStatus || waba.status || '—' }}
            </p>
          </div>
        </div>
        <p v-else class="text-n-slate-11">{{ $t('YCLOUD.DASHBOARD.NO_WABA') }}</p>
      </SettingsSection>

      <!-- Recent Events -->
      <SettingsSection
        :title="$t('YCLOUD.DASHBOARD.EVENTS')"
        :sub-title="$t('YCLOUD.DASHBOARD.EVENTS_DESC')"
        :show-border="false"
      >
        <div v-if="Object.keys(lastEvents).length">
          <div
            v-for="(event, key) in lastEvents"
            :key="key"
            class="p-3 bg-n-slate-1 rounded-lg mb-2"
          >
            <p class="font-medium text-sm">{{ key }}</p>
            <p class="text-xs text-n-slate-11 mt-1">{{ event.timestamp }}</p>
          </div>
        </div>
        <p v-else class="text-n-slate-11">{{ $t('YCLOUD.DASHBOARD.NO_EVENTS') }}</p>
      </SettingsSection>
    </div>
  </div>
</template>
