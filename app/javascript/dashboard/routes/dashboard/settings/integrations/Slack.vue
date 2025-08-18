<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import Integration from './Integration.vue';
import SelectChannelWarning from './Slack/SelectChannelWarning.vue';
import SlackIntegrationHelpText from './Slack/SlackIntegrationHelpText.vue';
import Spinner from 'shared/components/Spinner.vue';

const props = defineProps({
  code: { type: String, default: '' },
});

const store = useStore();
const router = useRouter();
const route = useRoute();
const { t } = useI18n();

const integrationLoaded = ref(false);

const integration = computed(() => {
  return store.getters['integrations/getIntegration']('slack');
});

const areHooksAvailable = computed(() => {
  const { hooks = [] } = integration.value || {};
  return !!hooks.length;
});

const hook = computed(() => {
  const { hooks = [] } = integration.value || {};
  const [firstHook] = hooks;
  return firstHook || {};
});

const isIntegrationHookEnabled = computed(() => {
  return hook.value.status || false;
});

const hasConnectedAChannel = computed(() => {
  return !!hook.value.reference_id;
});

const selectedChannelName = computed(() => {
  if (hook.value.status) {
    const { settings: { channel_name: channelName = '' } = {} } = hook.value;
    return channelName || 'customer-conversations';
  }
  return t('INTEGRATION_SETTINGS.SLACK.HELP_TEXT.SELECTED');
});

const uiFlags = computed(() => store.getters['integrations/getUIFlags']);

const integrationAction = computed(() => {
  if (integration.value.enabled) {
    return 'disconnect';
  }
  return integration.value.action;
});

const intializeSlackIntegration = async () => {
  await store.dispatch('integrations/get', 'slack');
  if (props.code) {
    await store.dispatch('integrations/connectSlack', props.code);
    // Clear the query param `code` from the URL as the
    // subsequent reloads would result in an error
    router.replace(route.path);
  }
  integrationLoaded.value = true;
};

onMounted(() => {
  intializeSlackIntegration();
});
</script>

<template>
  <div
    v-if="integrationLoaded && !uiFlags.isCreatingSlack"
    class="flex flex-col flex-1 overflow-auto gap-5 pt-1 pb-10"
  >
    <Integration
      :integration-id="integration.id"
      :integration-logo="integration.logo"
      :integration-name="integration.name"
      :integration-description="integration.description"
      :integration-enabled="integration.enabled"
      :integration-action="integrationAction"
      :action-button-text="$t('INTEGRATION_SETTINGS.SLACK.DELETE')"
      :delete-confirmation-text="{
        title: $t('INTEGRATION_SETTINGS.SLACK.DELETE_CONFIRMATION.TITLE'),
        message: $t('INTEGRATION_SETTINGS.SLACK.DELETE_CONFIRMATION.MESSAGE'),
      }"
    />
    <div v-if="areHooksAvailable" class="flex-1">
      <SelectChannelWarning
        v-if="!isIntegrationHookEnabled"
        :has-connected-a-channel="hasConnectedAChannel"
      />
      <SlackIntegrationHelpText :selected-channel-name="selectedChannelName" />
    </div>
  </div>
  <div v-else class="flex items-center justify-center flex-1">
    <Spinner size="" color-scheme="primary" />
  </div>
</template>
