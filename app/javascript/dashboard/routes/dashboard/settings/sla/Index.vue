<template>
  <settings-layout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('SLA.LOADING')"
  >
    <template #header>
      <SLA-header :show-actions="records.length > 0" @click="openAddPopup" />
    </template>
    <template #loading>
      <SLAListItemLoading v-for="ii in 2" :key="ii" class="mb-3" />
    </template>
    <template #body>
      <SLAPaywall v-if="isBehindAPaywall" :is-admin="isAdmin" />
      <SLAEmptyState
        v-else-if="!records.length"
        @primary-action="openAddPopup"
      />
      <div v-else class="flex flex-col w-full h-full gap-3">
        <SLA-list-item
          v-for="sla in records"
          :key="sla.title"
          :sla-name="sla.name"
          :description="sla.description"
          :first-response="displayTime(sla.first_response_time_threshold)"
          :next-response="displayTime(sla.next_response_time_threshold)"
          :resolution-time="displayTime(sla.resolution_time_threshold)"
          :has-business-hours="sla.only_during_business_hours"
          :is-loading="loading[sla.id]"
          @click="openDeletePopup(sla)"
        />
      </div>

      <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
        <add-SLA @close="hideAddPopup" />
      </woot-modal>

      <woot-delete-modal
        :show.sync="showDeleteConfirmationPopup"
        :on-close="closeDeletePopup"
        :on-confirm="confirmDeletion"
        :title="$t('SLA.DELETE.CONFIRM.TITLE')"
        :message="$t('SLA.DELETE.CONFIRM.MESSAGE')"
        :message-value="deleteMessage"
        :confirm-text="deleteConfirmText"
        :reject-text="deleteRejectText"
      />
    </template>
  </settings-layout>
</template>
<script>
import AddSLA from './AddSLA.vue';
import SettingsLayout from '../SettingsLayout.vue';
import SLAEmptyState from './components/SLAEmptyState.vue';
import SLAHeader from './components/SLAHeader.vue';
import SLAListItem from './components/SLAListItem.vue';
import SLAListItemLoading from './components/SLAListItemLoading.vue';
import SLAPaywall from './components/SLAPaywall.vue';

import { mapGetters } from 'vuex';
import { convertSecondsToTimeUnit } from '@chatwoot/utils';
import alertMixin from 'shared/mixins/alertMixin';
import adminMixin from 'dashboard/mixins/isAdmin';

export default {
  components: {
    AddSLA,
    SettingsLayout,
    SLAEmptyState,
    SLAHeader,
    SLAListItem,
    SLAListItemLoading,
    SLAPaywall,
  },
  mixins: [alertMixin, adminMixin],
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
      records: 'sla/getSLA',
      uiFlags: 'sla/getUIFlags',
      accountId: 'getCurrentAccountId',
      getAccount: 'accounts/getAccount',
      isTrialAccount: 'accounts/isTrialAccount',
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
      if (!this.isOnChatwootCloud) {
        return false;
      }

      const isTrial = this.isTrialAccount(this.accountId);
      if (isTrial) return false;

      const currentPlan = this.currentPlan();
      if (!currentPlan) return true;

      return ['Hacker', 'Startup'].includes(currentPlan);
    },
  },
  mounted() {
    this.$store.dispatch('sla/get');
  },
  methods: {
    openAddPopup() {
      this.showAddPopup = true;
    },
    currentPlan() {
      const account = this.getAccount(this.accountId);
      if (!account) return '';

      return account.custom_attributes?.plan_name || '';
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
          this.showAlert(this.$t('SLA.DELETE.API.SUCCESS_MESSAGE'));
        })
        .catch(() => {
          this.showAlert(this.$t('SLA.DELETE.API.ERROR_MESSAGE'));
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
  },
};
</script>
