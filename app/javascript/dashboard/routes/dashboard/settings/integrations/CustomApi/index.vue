<template>
  <div class="flex-1 p-4 overflow-auto">
    <woot-button
      color-scheme="success"
      class-names="button--fixed-top"
      icon="add-circle"
      @click="openCreatePopup"
    >
      {{ $t('INTEGRATION_SETTINGS.CUSTOM_API.HEADER_BTN_TXT') }}
    </woot-button>
    <div class="flex flex-row gap-4">
      <div class="w-full lg:w-3/5">
        <p
          v-if="!uiFlags.isFetching && !records.length"
          class="flex flex-col items-center justify-center h-full"
        >
          {{ $t('INTEGRATION_SETTINGS.CUSTOM_API.LIST.404') }}
        </p>
        <woot-loading-state
          v-if="uiFlags.isFetching"
          :message="$t('INTEGRATION_SETTINGS.CUSTOM_API.LIST.LOADING')"
        />
        <table v-if="!uiFlags.isFetching && records.length" class="woot-table">
          <thead>
            <th
              v-for="thHeader in $t(
                'INTEGRATION_SETTINGS.CUSTOM_API.LIST.TABLE_HEADER'
              )"
              :key="thHeader"
            >
              {{ thHeader }}
            </th>
          </thead>
          <tbody>
            <custom-api-row
              v-for="(customApiItem, index) in records"
              :key="customApiItem.id"
              :index="index"
              :app="customApiItem"
              @edit="editApp"
              @delete="openDeletePopup"
            />
          </tbody>
        </table>
      </div>

      <div class="hidden w-1/3 lg:block">
        <span
          v-dompurify-html="
            useInstallationName(
              $t('INTEGRATION_SETTINGS.CUSTOM_API.SIDEBAR_TXT'),
              globalConfig.installationName
            )
          "
        />
      </div>
    </div>

    <custom-api-modal
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
      :title="$t('INTEGRATION_SETTINGS.CUSTOM_API.DELETE.TITLE')"
      :message="
        $t('INTEGRATION_SETTINGS.CUSTOM_API.DELETE.MESSAGE', {
          appName: selectedApp.title,
        })
      "
      :confirm-text="$t('INTEGRATION_SETTINGS.CUSTOM_API.DELETE.CONFIRM_YES')"
      :reject-text="$t('INTEGRATION_SETTINGS.CUSTOM_API.DELETE.CONFIRM_NO')"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import CustomApiModal from './CustomApiModal.vue';
import CustomApiRow from './CustomApiRow.vue';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

export default {
  components: {
    CustomApiModal,
    CustomApiRow,
  },
  mixins: [globalConfigMixin],
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
      records: 'customApi/getRecords',
      uiFlags: 'customApi/getUIFlags',
    }),
  },

  mounted() {
    this.$store.dispatch('customApi/get');
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
        await this.$store.dispatch('customApi/delete', id);
        useAlert(this.$t('INTEGRATION_SETTINGS.CUSTOM_API.DELETE.API_SUCCESS'));
      } catch (error) {
        useAlert(this.$t('INTEGRATION_SETTINGS.CUSTOM_API.DELETE.API_ERROR'));
      }
    },
  },
};
</script>
