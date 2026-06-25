<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { picoSearch } from '@scmmishra/pico-search';
import { BaseTable } from 'dashboard/components-next/table';
import DashboardAppModal from './DashboardAppModal.vue';
import DashboardAppsRow from './DashboardAppsRow.vue';
import BaseSettingsHeader from '../../components/BaseSettingsHeader.vue';
import SettingsLayout from '../../SettingsLayout.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    BaseSettingsHeader,
    SettingsLayout,
    BaseTable,
    DashboardAppModal,
    DashboardAppsRow,
    NextButton,
  },
  data() {
    return {
      loading: {},
      showDashboardAppPopup: false,
      showDeleteConfirmationPopup: false,
      selectedApp: {},
      mode: 'CREATE',
      searchQuery: '',
    };
  },
  computed: {
    ...mapGetters({
      records: 'dashboardApps/getRecords',
      uiFlags: 'dashboardApps/getUIFlags',
    }),
    filteredRecords() {
      const query = this.searchQuery.trim();
      if (!query) return this.records;
      return picoSearch(this.records, query, ['title']);
    },
    tableHeaders() {
      return [
        this.$t('INTEGRATION_SETTINGS.DASHBOARD_APPS.LIST.TABLE_HEADER.NAME'),
        this.$t(
          'INTEGRATION_SETTINGS.DASHBOARD_APPS.LIST.TABLE_HEADER.ENDPOINT'
        ),
        this.$t(
          'INTEGRATION_SETTINGS.DASHBOARD_APPS.LIST.TABLE_HEADER.ACTIONS'
        ),
      ];
    },
  },
  mounted() {
    this.$store.dispatch('dashboardApps/get');
  },
  methods: {
    toggleDashboardAppPopup() {
      this.showDashboardAppPopup = !this.showDashboardAppPopup;
      this.selectedApp = {};
    },
    openDeletePopup(response) {
      this.showDeleteConfirmationPopup = true;
      this.selectedApp = response;
    },
    openCreatePopup() {
      this.mode = 'CREATE';
      this.selectedApp = {};
      this.showDashboardAppPopup = true;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    editApp(app) {
      this.loading[app.id] = true;
      this.mode = 'UPDATE';
      this.selectedApp = app;
      this.showDashboardAppPopup = true;
    },
    confirmDeletion() {
      this.loading[this.selectedApp.id] = true;
      this.closeDeletePopup();
      this.deleteApp(this.selectedApp.id);
    },
    async deleteApp(id) {
      try {
        await this.$store.dispatch('dashboardApps/delete', id);
        useAlert(
          this.$t('INTEGRATION_SETTINGS.DASHBOARD_APPS.DELETE.API_SUCCESS')
        );
      } catch (error) {
        useAlert(
          this.$t('INTEGRATION_SETTINGS.DASHBOARD_APPS.DELETE.API_ERROR')
        );
      }
    },
  },
};
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('INTEGRATION_SETTINGS.DASHBOARD_APPS.LIST.LOADING')"
    :no-records-found="!records.length"
    :no-records-message="$t('INTEGRATION_SETTINGS.DASHBOARD_APPS.LIST.404')"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="$t('INTEGRATION_SETTINGS.DASHBOARD_APPS.TITLE')"
        :description="$t('INTEGRATION_SETTINGS.DASHBOARD_APPS.DESCRIPTION')"
        :link-text="$t('INTEGRATION_SETTINGS.DASHBOARD_APPS.LEARN_MORE')"
        :search-placeholder="
          $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.SEARCH_PLACEHOLDER')
        "
        feature-name="dashboard_apps"
        :back-button-label="$t('INTEGRATION_SETTINGS.HEADER')"
      >
        <template v-if="records?.length" #count>
          <span class="text-body-main text-n-slate-11">
            {{
              $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.COUNT', {
                n: records.length,
              })
            }}
          </span>
        </template>
        <template #actions>
          <NextButton
            :label="$t('INTEGRATION_SETTINGS.DASHBOARD_APPS.HEADER_BTN_TXT')"
            size="sm"
            @click="openCreatePopup"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <span
        v-if="!filteredRecords.length && searchQuery"
        class="flex-1 flex items-center justify-center py-20 text-center text-body-main !text-base text-n-slate-11"
      >
        {{ $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.NO_RESULTS') }}
      </span>
      <BaseTable v-else :headers="tableHeaders" :items="filteredRecords">
        <template #row="{ items }">
          <DashboardAppsRow
            v-for="(dashboardAppItem, index) in items"
            :key="dashboardAppItem.id"
            :index="index"
            :app="dashboardAppItem"
            @edit="editApp"
            @delete="openDeletePopup"
          />
        </template>
      </BaseTable>
    </template>
    <DashboardAppModal
      v-if="showDashboardAppPopup"
      :show="showDashboardAppPopup"
      :mode="mode"
      :selected-app-data="selectedApp"
      @close="toggleDashboardAppPopup"
    />

    <woot-delete-modal
      v-model:show="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('INTEGRATION_SETTINGS.DASHBOARD_APPS.DELETE.TITLE')"
      :message="
        $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.DELETE.MESSAGE', {
          appName: selectedApp.title,
        })
      "
      :confirm-text="
        $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.DELETE.CONFIRM_YES')
      "
      :reject-text="$t('INTEGRATION_SETTINGS.DASHBOARD_APPS.DELETE.CONFIRM_NO')"
    />
  </SettingsLayout>
</template>
