<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { useBranding } from 'shared/composables/useBranding';

const props = defineProps({
  selectedChannelName: {
    type: String,
    required: true,
  },
  messageMode: {
    type: String,
    required: true,
  },
});

const { t } = useI18n();
const { formatMessage } = useMessageFormatter();
const { replaceInstallationName } = useBranding();

const formattedHelpText = computed(() => {
  const bodyKey =
    props.messageMode === 'alert'
      ? 'INTEGRATION_SETTINGS.SLACK.HELP_TEXT.BODY_ALERT'
      : 'INTEGRATION_SETTINGS.SLACK.HELP_TEXT.BODY';
  return formatMessage(
    replaceInstallationName(
      t(bodyKey, { selectedChannelName: props.selectedChannelName })
    ),
    false
  );
});
</script>

<template>
  <div
    class="flex-1 w-full px-6 py-5 outline outline-n-container outline-1 bg-n-card rounded-xl"
  >
    <div class="prose-lg max-w-5xl">
      <h5 class="text-n-slate-12 text-heading-1 tracking-tight">
        {{ t('INTEGRATION_SETTINGS.SLACK.HELP_TEXT.TITLE') }}
      </h5>
      <div
        v-dompurify-html="formattedHelpText"
        class="text-n-slate-11 text-body-main"
      />
    </div>
  </div>
</template>
