<template>
  <div class="wizard-body small-9 columns">
    <page-header
      :header-title="$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.DESC')"
    />
    <loading-state
      v-if="isCreating"
      message="Creating Email Support Channel"
    ></loading-state>
    <form v-if="!isCreating" class="row" @submit.prevent="createChannel()">
      <div class="medium-12 columns">
        <label>
          {{ $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.CHANNEL_NAME.LABEL') }}
          <input
            v-model.trim="channelName"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.CHANNEL_NAME.PLACEHOLDER')
            "
          />
        </label>
      </div>
      <div class="medium-12 columns">
        <label>
          {{ $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.CHANNEL_EMAIL_ADDRESS.LABEL') }}
          <div class="input-group">
            <input
              v-model.trim="emailAddress"
              type="text"
              :placeholder="
                $t(
                  'INBOX_MGMT.ADD.EMAIL_CHANNEL.CHANNEL_EMAIL_ADDRESS.PLACEHOLDER'
                )
              "
            />
            <span class="input-group-label">@support.chatwoot.com</span>
          </div>
        </label>
      </div>
      <div class="modal-footer">
        <div class="medium-12 columns">
          <woot-submit-button
            :button-text="$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.SUBMIT_BUTTON')"
          />
        </div>
      </div>
    </form>
  </div>
</template>

<script>
import router from '../../../index';
import PageHeader from '../SettingsSubPageHeader';

export default {
  components: {
    PageHeader,
  },
  data() {
    return {
      channelName: '',
      emailAddress: '',
      isCreating: false,
    };
  },
  created() {},
  methods: {
    async createChannel() {
      try {
        this.isCreating = true;
        const response = await this.$store.dispatch('addEmailChannel', {
          params: {
            name: this.channelName,
            email: this.emailAddress,
          },
        });
        router.replace({
          name: 'settings_inboxes_add_agents',
          params: { page: 'new', inbox_id: response.data.id },
        });
      } catch (error) {
        this.isCreating = false;
      }
    },
  },
};
</script>
