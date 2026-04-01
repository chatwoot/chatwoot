<script>
import AddSLA from './AddSLA.vue';
import SettingsLayout from '../SettingsLayout.vue';
import SLAEmptyState from './components/SLAEmptyState.vue';
import SLAHeader from './components/SLAHeader.vue';
import SLAListItem from './components/SLAListItem.vue';
import SLAListItemLoading from './components/SLAListItemLoading.vue';
import SLAPaywallEnterprise from './components/SLAPaywallEnterprise.vue';
import ConfirmDialog from 'dashboard/components-next/dialog/Dialog.vue';

import { mapGetters } from 'vuex';
import { convertSecondsToTimeUnit } from '@chatwoot/utils';
import { useAlert } from 'dashboard/composables';

export default {
  components: {
    AddSLA,
    SettingsLayout,
    SLAEmptyState,
    SLAHeader,
    SLAListItem,
    SLAListItemLoading,
    SLAPaywallEnterprise,
    ConfirmDialog,
  },
  data() {
    return {
      loading: {},
      showAddPopup: false,
      selectedResponse: {},
    };
  },
  computed: {
    ...mapGetters({
      isOnChatwootCloud: 'globalConfig/isOnChatwootCloud',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
      records: 'sla/getSLA',
      currentUser: 'getCurrentUser',
      accountId: 'getCurrentAccountId',
      uiFlags: 'sla/getUIFlags',
    }),
    deleteDescription() {
      return this.$t('SLA.DELETE.CONFIRM.MESSAGE', {
        name: this.selectedResponse?.name || '',
      });
    },
    isBehindAPaywall() {
      return !this.isFeatureEnabledonAccount(this.accountId, 'sla');
    },
    isSuperAdmin() {
      return this.currentUser.type === 'SuperAdmin';
    },
  },
  mounted() {
    this.$store.dispatch('sla/get');
  },
  methods: {
    openAddPopup() {
      if (this.isBehindAPaywall) {
        return;
      }
      this.showAddPopup = true;
    },
    hideAddPopup() {
      this.showAddPopup = false;
    },
    openDeletePopup(response) {
      this.selectedResponse = response;
      this.$nextTick(() => {
        this.$refs.deleteSlaDialog?.open();
      });
    },
    confirmDeletion() {
      const id = this.selectedResponse.id;
      this.loading[id] = true;
      this.$refs.deleteSlaDialog?.close();
      this.deleteSla(id);
    },
    deleteSla(id) {
      this.$store
        .dispatch('sla/delete', id)
        .then(() => {
          useAlert(this.$t('SLA.DELETE.API.SUCCESS_MESSAGE'));
        })
        .catch(() => {
          useAlert(this.$t('SLA.DELETE.API.ERROR_MESSAGE'));
        })
        .finally(() => {
          this.loading[id] = false;
        });
    },
    displayTime(threshold) {
      const { time, unit } = convertSecondsToTimeUnit(threshold, {
        minute: 'm',
        hour: 'h',
        day: 'd',
      });
      if (!time) return '-';
      return `${time}${unit}`;
    },
    onClickCTA() {
      this.$router.push({
        name: 'billing_settings_index',
        params: { accountId: this.accountId },
      });
    },
  },
};
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('SLA.LIST.LOADING')"
  >
    <template #header>
      <SLAHeader :show-actions="!isBehindAPaywall" @add="openAddPopup" />
    </template>
    <template #loading>
      <div
        class="overflow-x-auto rounded-2xl border border-outline-variant/10 shadow-xl"
      >
        <div class="flex flex-col gap-3 bg-surface-container-low p-4 sm:p-6">
          <SLAListItemLoading v-for="ii in 2" :key="ii" />
        </div>
      </div>
    </template>
    <template #body>
      <SLAPaywallEnterprise
        v-if="isBehindAPaywall"
        :is-super-admin="isSuperAdmin"
        :is-on-chatwoot-cloud="isOnChatwootCloud"
        @upgrade="onClickCTA"
      />
      <SLAEmptyState
        v-else-if="!records.length"
        @primary-action="openAddPopup"
      />
      <div
        v-else
        class="overflow-x-auto rounded-2xl border border-outline-variant/10 shadow-xl"
      >
        <div class="flex flex-col gap-3 bg-surface-container-low p-4 sm:p-6">
          <SLAListItem
            v-for="sla in records"
            :key="sla.id"
            :sla-name="sla.name"
            :description="sla.description"
            :first-response="displayTime(sla.first_response_time_threshold)"
            :next-response="displayTime(sla.next_response_time_threshold)"
            :resolution-time="displayTime(sla.resolution_time_threshold)"
            :has-business-hours="sla.only_during_business_hours"
            :is-loading="loading[sla.id]"
            @delete="openDeletePopup(sla)"
          />
        </div>
      </div>

      <woot-modal
        v-model:show="showAddPopup"
        size="medium"
        :on-close="hideAddPopup"
      >
        <AddSLA v-if="showAddPopup" @close="hideAddPopup" />
      </woot-modal>

      <ConfirmDialog
        ref="deleteSlaDialog"
        type="alert"
        :title="$t('SLA.DELETE.CONFIRM.TITLE')"
        :description="deleteDescription"
        :confirm-button-label="$t('SLA.DELETE.CONFIRM.YES')"
        :cancel-button-label="$t('SLA.DELETE.CONFIRM.NO')"
        @confirm="confirmDeletion"
      />
    </template>
  </SettingsLayout>
</template>
