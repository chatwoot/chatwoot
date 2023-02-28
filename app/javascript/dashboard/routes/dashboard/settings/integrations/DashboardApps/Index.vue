<template>
  <div class="row content-box full-height">
    <woot-button
      color-scheme="success"
      class-names="button--fixed-top"
      icon="add-circle"
      @click="openCreatePopup"
    >
      {{ $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.HEADER_BTN_TXT') }}
    </woot-button>
    <div class="row">
      <div class="small-8 columns with-right-space ">
        <p
          v-if="!uiFlags.isFetching && !records.length"
          class="no-items-error-message"
        >
          {{ $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.LIST.404') }}
        </p>
        <woot-loading-state
          v-if="uiFlags.isFetching"
          :message="$t('INTEGRATION_SETTINGS.DASHBOARD_APPS.LIST.LOADING')"
        />
        <table v-if="!uiFlags.isFetching && records.length" class="woot-table">
          <thead>
            <th
              v-for="thHeader in $t(
                'INTEGRATION_SETTINGS.DASHBOARD_APPS.LIST.TABLE_HEADER'
              )"
              :key="thHeader"
            >
              {{ thHeader }}
            </th>
          </thead>
          <tbody>
            <dashboard-apps-row
              v-for="(dashboardAppItem, index) in records"
              :key="dashboardAppItem.id"
              :index="index"
              :app="dashboardAppItem"
              @edit="editApp"
              @delete="openDeletePopup"
            />
          </tbody>
        </table>
      </div>

      <div class="small-4 columns">
        <span
          v-dompurify-html="
            useInstallationName(
              $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.SIDEBAR_TXT'),
              globalConfig.installationName
            )
          "
        />
      </div>
    </div>

    <dashboard-app-modal
      v-if="showDashboardAppPopup"
      :show="showDashboardAppPopup"
      :mode="mode"
      :selected-app-data="selectedApp"
      @close="toggleDashboardAppPopup"
    />

    <woot-delete-modal
      :show.sync="showDeleteConfirmationPopup"
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
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import DashboardAppModal from './DashboardAppModal.vue';
import DashboardAppsRow from './DashboardAppsRow.vue';
import alertMixin from 'shared/mixins/alertMixin';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

export default {
  components: {
    DashboardAppModal,
    DashboardAppsRow,
  },
  mixins: [alertMixin, globalConfigMixin],
  data() {
    return {
      loading: {},
      showDashboardAppPopup: false,
      showDeleteConfirmationPopup: false,
      selectedApp: {},
      mode: 'CREATE',
    };
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
      records: 'dashboardApps/getRecords',
      uiFlags: 'dashboardApps/getUIFlags',
    }),
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
        this.showAlert(
          this.$t('INTEGRATION_SETTINGS.DASHBOARD_APPS.DELETE.API_SUCCESS')
        );
      } catch (error) {
        this.showAlert(
          this.$t('INTEGRATION_SETTINGS.DASHBOARD_APPS.DELETE.API_ERROR')
        );
      }
    },
  },
};
</script>
