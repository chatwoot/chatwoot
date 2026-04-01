<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useBranding } from 'shared/composables/useBranding';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import ConfirmDialog from 'dashboard/components-next/dialog/Dialog.vue';
import CustomBrandPolicyWrapper from 'dashboard/components/CustomBrandPolicyWrapper.vue';
import BackButton from 'dashboard/components/widgets/BackButton.vue';
import NewWebhook from './NewWebHook.vue';
import EditWebhook from './EditWebHook.vue';
import WebhookRow from './WebhookRow.vue';
import SettingsLayout from '../../SettingsLayout.vue';
import { getHelpUrlForFeature } from 'dashboard/helper/featureHelper';

export default {
  components: {
    SettingsLayout,
    NextButton,
    Icon,
    ConfirmDialog,
    CustomBrandPolicyWrapper,
    BackButton,
    NewWebhook,
    EditWebhook,
    WebhookRow,
  },
  setup() {
    const { replaceInstallationName } = useBranding();
    const webhookHelpURL = getHelpUrlForFeature('webhook');
    return { replaceInstallationName, webhookHelpURL };
  },
  data() {
    return {
      loading: {},
      showAddPopup: false,
      showEditPopup: false,
      selectedWebHook: {},
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
    tableHeaders() {
      return [
        this.$t(
          'INTEGRATION_SETTINGS.WEBHOOK.LIST.TABLE_HEADER.WEBHOOK_ENDPOINT'
        ),
        this.$t('INTEGRATION_SETTINGS.WEBHOOK.LIST.TABLE_HEADER.ACTIONS'),
      ];
    },
    deleteDescription() {
      const url = this.selectedWebHook?.url || '';
      const base = this.$t(
        'INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.MESSAGE'
      );
      if (!url) return base;
      const label = this.$t(
        'INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.URL_LABEL'
      );
      return `${base}\n\n${label}: ${url}`;
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
      this.selectedWebHook = response;
      this.$nextTick(() => {
        this.$refs.deleteWebhookDialog?.open();
      });
    },
    openEditPopup(webhook) {
      this.showEditPopup = true;
      this.selectedWebHook = webhook;
    },
    hideEditPopup() {
      this.showEditPopup = false;
    },
    confirmDeletion() {
      const id = this.selectedWebHook.id;
      this.loading[id] = true;
      this.$refs.deleteWebhookDialog?.close();
      this.deleteWebhook(id);
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
      :is-loading="uiFlags.fetchingList"
      :loading-message="$t('INTEGRATION_SETTINGS.WEBHOOK.LOADING')"
      :no-records-message="$t('INTEGRATION_SETTINGS.WEBHOOK.LIST.404')"
      :no-records-found="!records.length"
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
            <template v-if="integration.name">
              <p
                class="mb-0 text-[11px] font-bold uppercase tracking-widest text-on-surface-variant/70"
              >
                {{ $t('INTEGRATION_SETTINGS.WEBHOOK.PAGE_EYEBROW') }}
              </p>
              <h2
                class="mb-0 text-3xl font-bold tracking-tight text-on-surface"
              >
                {{ integration.name }}
              </h2>
              <p class="mb-0 max-w-2xl text-base text-on-primary-container">
                {{ replaceInstallationName(integration.description) }}
              </p>
              <CustomBrandPolicyWrapper
                :show-on-custom-branded-instance="false"
              >
                <a
                  v-if="webhookHelpURL"
                  :href="webhookHelpURL"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="inline-flex items-center gap-1 text-sm font-medium text-secondary hover:underline"
                >
                  {{ $t('INTEGRATION_SETTINGS.WEBHOOK.LEARN_MORE') }}
                  <Icon icon="i-lucide-chevron-right" class="size-4 shrink-0" />
                </a>
              </CustomBrandPolicyWrapper>
            </template>
          </div>
          <NextButton
            v-if="integration.name"
            solid
            teal
            lg
            icon="i-lucide-plus"
            :label="$t('INTEGRATION_SETTINGS.WEBHOOK.HEADER_BTN_TXT')"
            class="w-full shrink-0 rounded-xl font-bold shadow-none hover:shadow-[0_0_20px_rgba(4,190,153,0.4)] active:scale-[0.98] sm:w-auto"
            @click="openAddPopup"
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
                <WebhookRow
                  v-for="(webHookItem, index) in records"
                  :key="webHookItem.id"
                  :index="index"
                  :webhook="webHookItem"
                  @edit="openEditPopup"
                  @delete="openDeletePopup"
                />
              </tbody>
            </table>
          </div>
        </div>
        <p class="mt-6 text-xs font-medium text-on-primary-container">
          {{
            $t('INTEGRATION_SETTINGS.WEBHOOK.LIST.SHOWING_COUNT', {
              count: records.length,
            })
          }}
        </p>
      </template>
    </SettingsLayout>

    <woot-modal
      v-model:show="showAddPopup"
      size="medium"
      :on-close="hideAddPopup"
    >
      <NewWebhook v-if="showAddPopup" :on-close="hideAddPopup" />
    </woot-modal>

    <woot-modal
      v-model:show="showEditPopup"
      size="medium"
      :on-close="hideEditPopup"
    >
      <EditWebhook
        v-if="showEditPopup"
        :id="selectedWebHook.id"
        :value="selectedWebHook"
        :on-close="hideEditPopup"
      />
    </woot-modal>

    <ConfirmDialog
      ref="deleteWebhookDialog"
      type="alert"
      :title="$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.TITLE')"
      :description="deleteDescription"
      :confirm-button-label="
        $t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.YES')
      "
      :cancel-button-label="
        $t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.NO')
      "
      @confirm="confirmDeletion"
    />
  </div>
</template>
