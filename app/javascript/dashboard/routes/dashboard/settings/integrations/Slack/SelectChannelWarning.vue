<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

export default {
  mixins: [globalConfigMixin],
  props: {
    hasConnectedAChannel: {
      type: Boolean,
      default: true,
    },
  },
  setup() {
    const { formatMessage } = useMessageFormatter();
    return {
      formatMessage,
    };
  },
  data() {
    return { selectedChannelId: '', availableChannels: [] };
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
      uiFlags: 'integrations/getUIFlags',
    }),
    errorDescription() {
      return !this.hasConnectedAChannel
        ? this.$t('INTEGRATION_SETTINGS.SLACK.SELECT_CHANNEL.DESCRIPTION')
        : this.$t('INTEGRATION_SETTINGS.SLACK.SELECT_CHANNEL.EXPIRED');
    },
  },
  methods: {
    async fetchChannels() {
      try {
        this.availableChannels = await this.$store.dispatch(
          'integrations/listAllSlackChannels'
        );
        this.availableChannels.sort((c1, c2) => c1.name - c2.name);
      } catch {
        this.$t('INTEGRATION_SETTINGS.SLACK.FAILED_TO_FETCH_CHANNELS');
        this.availableChannels = [];
      }
    },
    async updateIntegration() {
      try {
        await this.$store.dispatch('integrations/updateSlack', {
          referenceId: this.selectedChannelId,
        });
        useAlert(this.$t('INTEGRATION_SETTINGS.SLACK.UPDATE_SUCCESS'));
      } catch (error) {
        useAlert(error.message || 'INTEGRATION_SETTINGS.SLACK.UPDATE_ERROR');
      }
    },
  },
};
</script>

<template>
  <div
    class="px-6 py-5 border border-n-amber-6 rounded-2xl bg-n-solid-2 shadow"
  >
    <div class="flex">
      <div class="flex-shrink-0 mt-0.5">
        <fluent-icon icon="alert" class="text-n-amber-12" size="24" />
      </div>
      <div class="ml-3">
        <p class="mb-1 text-base font-semibold text-n-slate-12">
          {{
            $t('INTEGRATION_SETTINGS.SLACK.SELECT_CHANNEL.ATTENTION_REQUIRED')
          }}
        </p>
        <div class="mt-2 text-sm text-n-slate-11">
          <p
            v-dompurify-html="formatMessage(
              useInstallationName(
                errorDescription,
                globalConfig.installationName
              ),
              false
            )
              "
          />
        </div>
      </div>
    </div>
    <div v-if="!hasConnectedAChannel" class="mt-2 ml-8">
      <woot-submit-button
        v-if="!availableChannels.length"
        button-class="smooth small warning"
        :loading="uiFlags.isFetchingSlackChannels"
        :button-text="$t('INTEGRATION_SETTINGS.SLACK.SELECT_CHANNEL.BUTTON_TEXT')
          "
        spinner-class="warning"
        @click="fetchChannels"
      />
      <div v-else class="inline-flex">
        <select
          v-model="selectedChannelId"
          class="h-8 py-1 mr-4 text-xs leading-4"
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
        <woot-submit-button
          button-class="smooth small success"
          :button-text="$t('INTEGRATION_SETTINGS.SLACK.SELECT_CHANNEL.UPDATE')"
          spinner-class="success"
          :loading="uiFlags.isUpdatingSlack"
          @click="updateIntegration"
        />
      </div>
    </div>
  </div>
</template>
