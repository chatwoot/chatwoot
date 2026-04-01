<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import DashboardAppModal from './DashboardAppModal.vue';
import DashboardAppsRow from './DashboardAppsRow.vue';
import SettingsLayout from '../../SettingsLayout.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import ConfirmDialog from 'dashboard/components-next/dialog/Dialog.vue';
import CustomBrandPolicyWrapper from 'dashboard/components/CustomBrandPolicyWrapper.vue';
import BackButton from 'dashboard/components/widgets/BackButton.vue';
import { getHelpUrlForFeature } from 'dashboard/helper/featureHelper';

export default {
  components: {
    SettingsLayout,
    NextButton,
    Icon,
    ConfirmDialog,
    CustomBrandPolicyWrapper,
    BackButton,
    DashboardAppModal,
    DashboardAppsRow,
  },
  setup() {
    const dashboardAppsHelpURL = getHelpUrlForFeature('dashboard_apps');
    return { dashboardAppsHelpURL };
  },
  data() {
    return {
      loading: {},
      showDashboardAppPopup: false,
      selectedApp: {},
      mode: 'CREATE',
    };
  },
  computed: {
    ...mapGetters({
      records: 'dashboardApps/getRecords',
      uiFlags: 'dashboardApps/getUIFlags',
    }),
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
    deleteDescription() {
      const name = this.selectedApp?.title || '';
      return this.$t('INTEGRATION_SETTINGS.DASHBOARD_APPS.DELETE.MESSAGE', {
        appName: name,
      });
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
      this.selectedApp = response;
      this.$nextTick(() => {
        this.$refs.deleteAppDialog?.open();
      });
    },
    openCreatePopup() {
      this.mode = 'CREATE';
      this.selectedApp = {};
      this.showDashboardAppPopup = true;
    },
    editApp(app) {
      this.mode = 'UPDATE';
      this.selectedApp = app;
      this.showDashboardAppPopup = true;
    },
    confirmDeletion() {
      const id = this.selectedApp.id;
      this.loading[id] = true;
      this.$refs.deleteAppDialog?.close();
      this.deleteApp(id);
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
      } finally {
        this.loading[id] = false;
      }
    },
  },
};
</script>

<template>
  <div>
    <SettingsLayout
      :is-loading="uiFlags.isFetching"
      :loading-message="$t('INTEGRATION_SETTINGS.DASHBOARD_APPS.LIST.LOADING')"
      :no-records-found="!records.length"
      :no-records-message="$t('INTEGRATION_SETTINGS.DASHBOARD_APPS.LIST.404')"
    >
      <template #header>
        <div
          class="flex flex-col gap-6 pb-2 sm:flex-row sm:items-end sm:justify-between"
        >
          <div class="min-w-0 space-y-2">
            <BackButton
              compact
              :button-label="$t('INTEGRATION_SETTINGS.HEADER')"
            />
            <p
              class="mb-0 text-[11px] font-bold uppercase tracking-widest text-on-surface-variant/70"
            >
              {{ $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.PAGE_EYEBROW') }}
            </p>
            <h2 class="mb-0 text-3xl font-bold tracking-tight text-on-surface">
              {{ $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.TITLE') }}
            </h2>
            <p class="mb-0 max-w-2xl text-base text-on-primary-container">
              {{ $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.DESCRIPTION') }}
            </p>
            <CustomBrandPolicyWrapper :show-on-custom-branded-instance="false">
              <a
                v-if="dashboardAppsHelpURL"
                :href="dashboardAppsHelpURL"
                target="_blank"
                rel="noopener noreferrer"
                class="inline-flex items-center gap-1 text-sm font-medium text-secondary hover:underline"
              >
                {{ $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.LEARN_MORE') }}
                <Icon icon="i-lucide-chevron-right" class="size-4 shrink-0" />
              </a>
            </CustomBrandPolicyWrapper>
          </div>
          <NextButton
            solid
            teal
            lg
            icon="i-lucide-plus"
            :label="$t('INTEGRATION_SETTINGS.DASHBOARD_APPS.HEADER_BTN_TXT')"
            class="w-full shrink-0 rounded-xl font-bold shadow-none hover:shadow-[0_0_20px_rgba(4,190,153,0.4)] active:scale-[0.98] sm:w-auto"
            @click="openCreatePopup"
          />
        </div>
      </template>
      <template #body>
        <div
          class="overflow-x-auto rounded-2xl border border-outline-variant/10 shadow-xl"
        >
          <div class="min-w-[36rem] bg-surface-container-low">
            <table class="min-w-full divide-y divide-surface-container-high/30">
              <thead>
                <tr
                  class="border-b border-surface-container-high/50 bg-surface-container-high/30"
                >
                  <th
                    v-for="thHeader in tableHeaders"
                    :key="thHeader"
                    class="px-6 py-4 text-start text-[11px] font-bold uppercase tracking-widest text-tertiary/60 last:text-end"
                  >
                    {{ thHeader }}
                  </th>
                </tr>
              </thead>
              <tbody
                class="divide-y divide-surface-container-high/30 text-on-surface [&>tr]:transition-colors [&>tr]:duration-150 [&>tr]:hover:bg-surface-container-high/20"
              >
                <DashboardAppsRow
                  v-for="dashboardAppItem in records"
                  :key="dashboardAppItem.id"
                  :app="dashboardAppItem"
                  @edit="editApp"
                  @delete="openDeletePopup"
                />
              </tbody>
            </table>
          </div>
        </div>
        <p class="mt-6 text-xs font-medium text-on-primary-container">
          {{
            $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.LIST.SHOWING_COUNT', {
              count: records.length,
            })
          }}
        </p>
      </template>
    </SettingsLayout>

    <DashboardAppModal
      v-if="showDashboardAppPopup"
      :show="showDashboardAppPopup"
      :mode="mode"
      :selected-app-data="selectedApp"
      @close="toggleDashboardAppPopup"
    />

    <ConfirmDialog
      ref="deleteAppDialog"
      type="alert"
      :title="$t('INTEGRATION_SETTINGS.DASHBOARD_APPS.DELETE.TITLE')"
      :description="deleteDescription"
      :confirm-button-label="
        $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.DELETE.CONFIRM_YES')
      "
      :cancel-button-label="
        $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.DELETE.CONFIRM_NO')
      "
      @confirm="confirmDeletion"
    />
  </div>
</template>
