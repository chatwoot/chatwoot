<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useInstallationName } from 'shared/mixins/globalConfigMixin';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  hasConnectedAChannel: {
    type: Boolean,
    default: true,
  },
});

const store = useStore();
const { t } = useI18n();

const { formatMessage } = useMessageFormatter();

const selectedChannelId = ref('');
const availableChannels = ref([]);

const uiFlags = computed(() => store.getters['integrations/getUIFlags']);

const errorDescription = computed(() => {
  return !props.hasConnectedAChannel
    ? t('INTEGRATION_SETTINGS.SLACK.SELECT_CHANNEL.DESCRIPTION')
    : t('INTEGRATION_SETTINGS.SLACK.SELECT_CHANNEL.EXPIRED');
});
const globalConfig = computed(() => store.getters['globalConfig/get']);

const formattedErrorMessage = computed(() => {
  return formatMessage(
    useInstallationName(
      errorDescription.value,
      globalConfig.value.installationName
    ),
    false
  );
});

const fetchChannels = async () => {
  try {
    availableChannels.value = await store.dispatch(
      'integrations/listAllSlackChannels'
    );
    availableChannels.value.sort((c1, c2) => c1.name - c2.name);
  } catch {
    t('INTEGRATION_SETTINGS.SLACK.FAILED_TO_FETCH_CHANNELS');
    availableChannels.value = [];
  }
};

const updateIntegration = async () => {
  try {
    await store.dispatch('integrations/updateSlack', {
      referenceId: selectedChannelId.value,
    });
    useAlert(t('INTEGRATION_SETTINGS.SLACK.UPDATE_SUCCESS'));
  } catch (error) {
    useAlert(error.message || 'INTEGRATION_SETTINGS.SLACK.UPDATE_ERROR');
  }
};
</script>

<template>
  <div
    class="px-6 py-4 mb-4 outline outline-n-container outline-1 bg-n-alpha-3 rounded-md shadow"
  >
    <div class="flex">
      <div class="flex-shrink-0">
        <div class="i-lucide-bell text-xl text-n-amber-11 mt-1" />
      </div>
      <div class="ml-3">
        <p class="mb-1 text-base font-semibold text-n-slate-12">
          {{
            $t('INTEGRATION_SETTINGS.SLACK.SELECT_CHANNEL.ATTENTION_REQUIRED')
          }}
        </p>
        <div class="mt-2 text-sm text-n-slate-11 mb-3">
          <p v-dompurify-html="formattedErrorMessage" />
        </div>
      </div>
    </div>
    <div v-if="!hasConnectedAChannel" class="mb-2 mt-1 ml-8">
      <Button
        v-if="!availableChannels.length"
        amber
        sm
        :is-loading="uiFlags.isFetchingSlackChannels"
        @click="fetchChannels"
      >
        {{ $t('INTEGRATION_SETTINGS.SLACK.SELECT_CHANNEL.BUTTON_TEXT') }}
      </Button>
      <div v-else class="inline-flex">
        <select
          v-model="selectedChannelId"
          class="h-8 py-1 mr-4 text-xs leading-4 border border-yellow-300"
        >
          <option value="">
            {{ $t('INTEGRATION_SETTINGS.SLACK.SELECT_CHANNEL.OPTION_LABEL') }}
          </option>
          <option
            v-for="channel in availableChannels"
            :key="channel.id"
            :value="channel.id"
          >
            #{{ channel.name }}
          </option>
        </select>
        <Button
          teal
          sm
          :is-loading="uiFlags.isUpdatingSlack"
          @click="updateIntegration"
        >
          {{ $t('INTEGRATION_SETTINGS.SLACK.SELECT_CHANNEL.UPDATE') }}
        </Button>
      </div>
    </div>
  </div>
</template>
