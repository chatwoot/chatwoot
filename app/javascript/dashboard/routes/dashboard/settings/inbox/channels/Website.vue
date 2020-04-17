<template>
  <div class="wizard-body small-9 columns">
    <page-header
      :header-title="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.DESC')"
    />
    <woot-loading-state
      v-if="uiFlags.isCreating"
      :message="$('INBOX_MGMT.ADD.WEBSITE_CHANNEL.LOADING_MESSAGE')"
    >
    </woot-loading-state>
    <form
      v-if="!uiFlags.isCreating"
      class="row"
      @submit.prevent="createChannel()"
    >
      <div class="medium-12 columns">
        <label>
          {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_NAME.LABEL') }}
          <input
            v-model.trim="inboxName"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_NAME.PLACEHOLDER')
            "
          />
        </label>
      </div>
      <div class="medium-12 columns">
        <label>
          {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_DOMAIN.LABEL') }}
          <input
            v-model.trim="channelWebsiteUrl"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_DOMAIN.PLACEHOLDER')
            "
          />
        </label>
      </div>
      <div class="medium-12 columns">
        <label>
          {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TITLE.LABEL') }}
          <input
            v-model.trim="channelWelcomeTitle"
            type="text"
            :placeholder="
              $t(
                'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TITLE.PLACEHOLDER'
              )
            "
          />
        </label>
      </div>
      <div class="medium-12 columns">
        <label>
          {{
            $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TAGLINE.LABEL')
          }}
          <input
            v-model.trim="channelWelcomeTagline"
            type="text"
            :placeholder="
              $t(
                'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TAGLINE.PLACEHOLDER'
              )
            "
          />
        </label>
      </div>
      <div class="medium-12 columns">
        <label>
          {{
            $t(
              'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_AGENT_AWAY_MESSAGE.LABEL'
            )
          }}
          <input
            v-model.trim="channelAgentAwayMessage"
            type="text"
            :placeholder="
              $t(
                'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_AGENT_AWAY_MESSAGE.PLACEHOLDER'
              )
            "
          />
        </label>
      </div>

      <div class="medium-12 columns">
        <label>
          {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.WIDGET_COLOR.LABEL') }}
          <compact
            v-model="channelWidgetColor"
            class="widget-color--selector"
          />
        </label>
      </div>

      <div class="modal-footer">
        <div class="medium-12 columns">
          <woot-submit-button
            :loading="uiFlags.isCreating"
            :disabled="!channelWebsiteUrl || !inboxName"
            :button-text="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.SUBMIT_BUTTON')"
          />
        </div>
      </div>
    </form>
  </div>
</template>

<script>
import { Compact } from 'vue-color';
import { mapGetters } from 'vuex';
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader';

export default {
  components: {
    PageHeader,
    Compact,
  },
  data() {
    return {
      inboxName: '',
      channelWebsiteUrl: '',
      channelWidgetColor: { hex: '#009CE0' },
      channelWelcomeTitle: '',
      channelWelcomeTagline: '',
      channelAgentAwayMessage: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  methods: {
    async createChannel() {
      const website = await this.$store.dispatch(
        'inboxes/createWebsiteChannel',
        {
          name: this.inboxName,
          channel: {
            type: 'web_widget',
            website_url: this.channelWebsiteUrl,
            widget_color: this.channelWidgetColor.hex,
            welcome_title: this.channelWelcomeTitle,
            welcome_tagline: this.channelWelcomeTagline,
            agent_away_message: this.channelAgentAwayMessage,
          },
        }
      );
      router.replace({
        name: 'settings_inboxes_add_agents',
        params: {
          page: 'new',
          inbox_id: website.id,
        },
      });
    },
  },
};
</script>
