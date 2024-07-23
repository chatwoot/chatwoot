<template>
  <div
    class="px-6 py-4 mb-4 border border-yellow-200 rounded-md bg-yellow-50 dark:border-slate-700 dark:bg-slate-800"
  >
    <div class="flex">
      <div class="flex-shrink-0 mt-0.5">
        <fluent-icon
          icon="alert"
          class="text-yellow-500 dark:text-yellow-400"
          size="24"
        />
      </div>
      <div class="ml-3">
        <p
          class="mb-1 text-base font-semibold text-yellow-900 dark:text-yellow-500"
        >
          {{
            $t('INTEGRATION_SETTINGS.SLACK.SELECT_CHANNEL.ATTENTION_REQUIRED')
          }}
        </p>
        <div class="mt-2 text-sm text-yellow-800 dark:text-yellow-600">
          <p
            v-dompurify-html="
              formatMessage(
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
        :button-text="
          $t('INTEGRATION_SETTINGS.SLACK.SELECT_CHANNEL.BUTTON_TEXT')
        "
        spinner-class="warning"
        @click="fetchChannels"
      />
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
<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';

export default {
  mixins: [globalConfigMixin, messageFormatterMixin],
  props: {
    hasConnectedAChannel: {
      type: Boolean,
      default: true,
    },
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
