<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useBranding } from 'shared/composables/useBranding';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import WebhookForm from './WebhookForm.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  onClose: {
    type: Function,
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();
const { replaceInstallationName } = useBranding();

const createdWebhook = ref(null);

const uiFlags = computed(() => store.getters['webhooks/getUIFlags']);

const onSubmit = async webhook => {
  try {
    const result = await store.dispatch('webhooks/create', { webhook });
    createdWebhook.value = result;
  } catch (error) {
    const message =
      error.response.data.message ||
      t('INTEGRATION_SETTINGS.WEBHOOK.EDIT.API.ERROR_MESSAGE');
    useAlert(message);
  }
};

const handleCopySecret = async () => {
  await copyTextToClipboard(createdWebhook.value.secret);
  useAlert(t('INTEGRATION_SETTINGS.WEBHOOK.SECRET.COPY_SUCCESS'));
};
</script>

<template>
  <div class="h-auto overflow-auto flex flex-col">
    <template v-if="createdWebhook">
      <woot-modal-header
        :header-title="
          t('INTEGRATION_SETTINGS.WEBHOOK.ADD.API.SUCCESS_MESSAGE')
        "
      />
      <div class="px-8 pb-6">
        <p class="text-sm text-n-slate-11 mb-4">
          {{ t('INTEGRATION_SETTINGS.WEBHOOK.SECRET.CREATED_DESC') }}
        </p>
        <label>
          {{ t('INTEGRATION_SETTINGS.WEBHOOK.SECRET.LABEL') }}
          <div class="flex items-center gap-2">
            <input
              :value="createdWebhook.secret"
              type="text"
              readonly
              class="!mb-0 font-mono"
            />
            <NextButton
              v-tooltip.top="t('INTEGRATION_SETTINGS.WEBHOOK.SECRET.COPY')"
              icon="i-lucide-copy"
              slate
              faded
              @click="handleCopySecret"
            />
          </div>
        </label>
        <div class="flex justify-end mt-4">
          <NextButton
            blue
            :label="t('INTEGRATION_SETTINGS.WEBHOOK.SECRET.DONE')"
            @click="props.onClose()"
          />
        </div>
      </div>
    </template>
    <template v-else>
      <woot-modal-header
        :header-title="t('INTEGRATION_SETTINGS.WEBHOOK.ADD.TITLE')"
        :header-content="
          replaceInstallationName(t('INTEGRATION_SETTINGS.WEBHOOK.FORM.DESC'))
        "
      />
      <WebhookForm
        :is-submitting="uiFlags.creatingItem"
        :submit-label="t('INTEGRATION_SETTINGS.WEBHOOK.FORM.ADD_SUBMIT')"
        @submit="onSubmit"
        @cancel="props.onClose()"
      />
    </template>
  </div>
</template>
