<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { frontendURL } from '../../../../helper/URLHelper';
import { useAlert } from 'dashboard/composables';
import { useInstallationName } from 'shared/mixins/globalConfigMixin';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  integrationId: {
    type: [String, Number],
    required: true,
  },
  integrationName: { type: String, default: '' },
  integrationDescription: { type: String, default: '' },
  integrationEnabled: { type: Boolean, default: false },
  integrationAction: { type: String, default: '' },
  actionButtonText: { type: String, default: '' },
  deleteConfirmationText: { type: Object, default: () => ({}) },
});

const { t } = useI18n();
const store = useStore();
const router = useRouter();

const dialogRef = ref(null);

const accountId = computed(() => store.getters.getCurrentAccountId);
const globalConfig = computed(() => store.getters['globalConfig/get']);

const openDeletePopup = () => {
  if (dialogRef.value) {
    dialogRef.value.open();
  }
};

const closeDeletePopup = () => {
  if (dialogRef.value) {
    dialogRef.value.close();
  }
};

const deleteIntegration = async () => {
  try {
    await store.dispatch('integrations/deleteIntegration', props.integrationId);
    useAlert(t('INTEGRATION_SETTINGS.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.API.ERROR_MESSAGE'));
  }
};

const confirmDeletion = () => {
  closeDeletePopup();
  deleteIntegration();
  router.push({ name: 'settings_applications' });
};
</script>

<template>
  <div
    class="flex flex-col items-start justify-between lg:flex-row lg:items-center p-6 outline outline-n-container outline-1 bg-n-alpha-3 rounded-md shadow gap-6"
  >
    <div
      class="flex items-start lg:items-center justify-start flex-1 m-0 gap-6 flex-col lg:flex-row"
    >
      <div class="flex h-16 w-16 items-center justify-center flex-shrink-0">
        <img
          :src="`/dashboard/images/integrations/${integrationId}.png`"
          class="max-w-full rounded-md border border-n-weak shadow-sm block dark:hidden bg-n-alpha-3 dark:bg-n-alpha-2"
        />
        <img
          :src="`/dashboard/images/integrations/${integrationId}-dark.png`"
          class="max-w-full rounded-md border border-n-weak shadow-sm hidden dark:block bg-n-alpha-3 dark:bg-n-alpha-2"
        />
      </div>
      <div>
        <h3 class="mb-1 text-xl font-medium text-n-slate-12">
          {{ integrationName }}
        </h3>
        <p class="text-n-slate-11 text-sm leading-6">
          {{
            useInstallationName(
              integrationDescription,
              globalConfig.installationName
            )
          }}
        </p>
      </div>
    </div>
    <div class="flex justify-center items-center mb-0">
      <router-link
        :to="
          frontendURL(
            `accounts/${accountId}/settings/integrations/` + integrationId
          )
        "
      >
        <div v-if="integrationEnabled">
          <div v-if="integrationAction === 'disconnect'">
            <Button
              :label="
                actionButtonText ||
                $t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.BUTTON_TEXT')
              "
              faded
              ruby
              @click="openDeletePopup"
            />
          </div>
          <div v-else>
            <Button
              faded
              blue
              :label="t('INTEGRATION_SETTINGS.WEBHOOK.CONFIGURE')"
            />
          </div>
        </div>
      </router-link>
      <div v-if="!integrationEnabled">
        <slot name="action">
          <a :href="integrationAction">
            <Button
              faded
              blue
              :label="t('INTEGRATION_SETTINGS.CONNECT.BUTTON_TEXT')"
            />
          </a>
        </slot>
      </div>
    </div>
    <Dialog
      ref="dialogRef"
      type="alert"
      :title="
        deleteConfirmationText.title ||
        t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.TITLE')
      "
      :description="
        deleteConfirmationText.message ||
        t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.MESSAGE')
      "
      :confirm-button-label="
        t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.YES')
      "
      :cancel-button-label="t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.NO')"
      @confirm="confirmDeletion"
    />
  </div>
</template>
