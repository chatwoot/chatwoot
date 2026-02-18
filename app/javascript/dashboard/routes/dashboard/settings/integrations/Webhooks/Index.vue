<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useBranding } from 'shared/composables/useBranding';
import { picoSearch } from '@scmmishra/pico-search';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { BaseTable } from 'dashboard/components-next/table';
import NewWebhook from './NewWebHook.vue';
import EditWebhook from './EditWebHook.vue';
import WebhookRow from './WebhookRow.vue';
import BaseSettingsHeader from '../../components/BaseSettingsHeader.vue';
import SettingsLayout from '../../SettingsLayout.vue';

export default {
  components: {
    SettingsLayout,
    NextButton,
    BaseSettingsHeader,
    BaseTable,
    NewWebhook,
    EditWebhook,
    WebhookRow,
  },
  setup() {
    const { replaceInstallationName } = useBranding();
    return { replaceInstallationName };
  },
  data() {
    return {
      loading: {},
      showAddPopup: false,
      showEditPopup: false,
      showDeleteConfirmationPopup: false,
      selectedWebHook: {},
      searchQuery: '',
    };
  },
  computed: {
    ...mapGetters({
      records: 'webhooks/getWebhooks',
      uiFlags: 'webhooks/getUIFlags',
    }),
    integration() {
      return this.$store.getters['integrations/getIntegration']('webhook');
    },
    filteredRecords() {
      const query = this.searchQuery.trim();
      if (!query) return this.records;
      return picoSearch(this.records, query, ['name', 'url']);
    },
    tableHeaders() {
      return [
        this.$t(
          'INTEGRATION_SETTINGS.WEBHOOK.LIST.TABLE_HEADER.WEBHOOK_ENDPOINT'
        ),
        this.$t('INTEGRATION_SETTINGS.WEBHOOK.LIST.TABLE_HEADER.ACTIONS'),
      ];
    },
  },
  mounted() {
    this.$store.dispatch('webhooks/get');
  },
  methods: {
    openAddPopup() {
      this.showAddPopup = true;
    },
    hideAddPopup() {
      this.showAddPopup = false;
    },
    openDeletePopup(response) {
      this.showDeleteConfirmationPopup = true;
      this.selectedWebHook = response;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    openEditPopup(webhook) {
      this.showEditPopup = true;
      this.selectedWebHook = webhook;
    },
    hideEditPopup() {
      this.showEditPopup = false;
    },
    confirmDeletion() {
      this.loading[this.selectedWebHook.id] = true;
      this.closeDeletePopup();
      this.deleteWebhook(this.selectedWebHook.id);
    },
    async deleteWebhook(id) {
      try {
        await this.$store.dispatch('webhooks/delete', id);
        useAlert(
          this.$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.API.SUCCESS_MESSAGE')
        );
      } catch (error) {
        useAlert(
          this.$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.fetchingList"
    :loading-message="$t('INTEGRATION_SETTINGS.WEBHOOK.LOADING')"
    :no-records-message="$t('INTEGRATION_SETTINGS.WEBHOOK.LIST.404')"
    :no-records-found="!records.length"
  >
    <template #header>
      <BaseSettingsHeader
        v-if="integration.name"
        v-model:search-query="searchQuery"
        :title="integration.name"
        :description="replaceInstallationName(integration.description)"
        :link-text="$t('INTEGRATION_SETTINGS.WEBHOOK.LEARN_MORE')"
        :search-placeholder="
          $t('INTEGRATION_SETTINGS.WEBHOOK.SEARCH_PLACEHOLDER')
        "
        feature-name="webhook"
        :back-button-label="$t('INTEGRATION_SETTINGS.HEADER')"
      >
        <template v-if="records?.length" #count>
          <span class="text-body-main text-n-slate-11">
            {{
              $t('INTEGRATION_SETTINGS.WEBHOOK.COUNT', { n: records.length })
            }}
          </span>
        </template>
        <template #actions>
          <NextButton
            blue
            :label="$t('INTEGRATION_SETTINGS.WEBHOOK.HEADER_BTN_TXT')"
            size="sm"
            @click="openAddPopup"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <BaseTable
        :headers="tableHeaders"
        :items="filteredRecords"
        :no-data-message="
          searchQuery ? $t('INTEGRATION_SETTINGS.WEBHOOK.NO_RESULTS') : ''
        "
      >
        <template #row="{ items }">
          <WebhookRow
            v-for="(webHookItem, index) in items"
            :key="webHookItem.id"
            :index="index"
            :webhook="webHookItem"
            @edit="openEditPopup"
            @delete="openDeletePopup"
          />
        </template>
      </BaseTable>
    </template>
    <woot-modal v-model:show="showAddPopup" :on-close="hideAddPopup">
      <NewWebhook v-if="showAddPopup" :on-close="hideAddPopup" />
    </woot-modal>

    <woot-modal v-model:show="showEditPopup" :on-close="hideEditPopup">
      <EditWebhook
        v-if="showEditPopup"
        :id="selectedWebHook.id"
        :value="selectedWebHook"
        :on-close="hideEditPopup"
      />
    </woot-modal>
    <woot-delete-modal
      v-model:show="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.TITLE')"
      :message="
        $t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.MESSAGE', {
          webhookURL: selectedWebHook.url,
        })
      "
      :confirm-text="$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.YES')"
      :reject-text="$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.NO')"
    />
  </SettingsLayout>
</template>
