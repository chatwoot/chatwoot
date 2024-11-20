<script>
import AddSLA from './AddSLA.vue';
import SettingsLayout from '../SettingsLayout.vue';
import SLAEmptyState from './components/SLAEmptyState.vue';
import SLAHeader from './components/SLAHeader.vue';
import SLAListItem from './components/SLAListItem.vue';
import SLAListItemLoading from './components/SLAListItemLoading.vue';
import SLAPaywallEnterprise from './components/SLAPaywallEnterprise.vue';

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
  },
  data() {
    return {
      loading: {},
      showAddPopup: false,
      showDeleteConfirmationPopup: false,
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
    deleteConfirmText() {
      return this.$t('SLA.DELETE.CONFIRM.YES');
    },
    deleteRejectText() {
      return this.$t('SLA.DELETE.CONFIRM.NO');
    },
    deleteMessage() {
      return ` ${this.selectedResponse.name}`;
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
      this.showDeleteConfirmationPopup = true;
      this.selectedResponse = response;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    confirmDeletion() {
      this.loading[this.selectedResponse.id] = true;
      this.closeDeletePopup();
      this.deleteSla(this.selectedResponse.id);
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
          this.loading[this.selectedResponse.id] = false;
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
    :loading-message="$t('SLA.LOADING')"
  >
    <template #header>
      <SLAHeader :show-actions="records.length > 0" @add="openAddPopup" />
    </template>
    <template #loading>
      <SLAListItemLoading v-for="ii in 2" :key="ii" class="mb-3" />
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
      <div v-else class="flex flex-col w-full h-full gap-3">
        <SLAListItem
          v-for="sla in records"
          :key="sla.title"
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

      <woot-modal v-model:show="showAddPopup" :on-close="hideAddPopup">
        <AddSLA @close="hideAddPopup" />
      </woot-modal>

      <woot-delete-modal
        v-model:show="showDeleteConfirmationPopup"
        :on-close="closeDeletePopup"
        :on-confirm="confirmDeletion"
        :title="$t('SLA.DELETE.CONFIRM.TITLE')"
        :message="$t('SLA.DELETE.CONFIRM.MESSAGE')"
        :message-value="deleteMessage"
        :confirm-text="deleteConfirmText"
        :reject-text="deleteRejectText"
      />
    </template>
  </SettingsLayout>
</template>
