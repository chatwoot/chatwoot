<script setup>
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useBranding } from 'shared/composables/useBranding';
import RadioCard from 'dashboard/components-next/radioCard/RadioCard.vue';

defineProps({
  messageMode: {
    type: String,
    required: true,
  },
});

const MESSAGE_MODES = [
  { id: 'two_way', key: 'TWO_WAY' },
  { id: 'alert', key: 'ALERT' },
];

const store = useStore();
const { t } = useI18n();
const { replaceInstallationName } = useBranding();

const onSelect = async messageMode => {
  try {
    await store.dispatch('integrations/updateSlack', { messageMode });
    useAlert(t('INTEGRATION_SETTINGS.SLACK.MESSAGE_MODE.UPDATE_SUCCESS'));
  } catch (error) {
    useAlert(error.message || t('INTEGRATION_SETTINGS.SLACK.UPDATE_ERROR'));
  }
};
</script>

<template>
  <div
    class="flex-1 w-full px-6 py-5 mb-4 outline outline-n-container outline-1 bg-n-card rounded-xl"
  >
    <h5 class="text-n-slate-12 text-heading-1 tracking-tight">
      {{ t('INTEGRATION_SETTINGS.SLACK.MESSAGE_MODE.TITLE') }}
    </h5>
    <p class="mt-1 mb-4 text-n-slate-11 text-body-main">
      {{ t('INTEGRATION_SETTINGS.SLACK.MESSAGE_MODE.DESCRIPTION') }}
    </p>
    <div class="grid gap-3 sm:grid-cols-2">
      <RadioCard
        v-for="mode in MESSAGE_MODES"
        :id="mode.id"
        :key="mode.id"
        name="slack-message-mode"
        :label="
          t(`INTEGRATION_SETTINGS.SLACK.MESSAGE_MODE.OPTIONS.${mode.key}.LABEL`)
        "
        :description="
          replaceInstallationName(
            t(
              `INTEGRATION_SETTINGS.SLACK.MESSAGE_MODE.OPTIONS.${mode.key}.DESCRIPTION`
            )
          )
        "
        :is-active="messageMode === mode.id"
        @select="onSelect"
      />
    </div>
  </div>
</template>
