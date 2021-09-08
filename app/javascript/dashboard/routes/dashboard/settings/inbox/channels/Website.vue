<template>
  <div class="wizard-body height-auto small-9 columns">
    <page-header
      :header-title="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.DESC')"
    />
    <woot-loading-state
      v-if="uiFlags.isCreating"
      :message="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.LOADING_MESSAGE')"
    />
    <form
      v-if="!uiFlags.isCreating"
      class="row"
      @submit.prevent="createChannel"
    >
      <div class="medium-12 columns">
        <label>
          {{ $t('INBOX_MGMT.ADD.WEBSITE_NAME.LABEL') }}
          <input
            v-model.trim="inboxName"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.WEBSITE_NAME.PLACEHOLDER')"
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
          {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.WIDGET_COLOR.LABEL') }}
          <woot-color-picker v-model="channelWidgetColor" />
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
      <label class="medium-12 columns">
        {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_TOGGLE.LABEL') }}
        <select v-model="greetingEnabled">
          <option :value="true">
            {{
              $t(
                'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_TOGGLE.ENABLED'
              )
            }}
          </option>
          <option :value="false">
            {{
              $t(
                'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_TOGGLE.DISABLED'
              )
            }}
          </option>
        </select>
        <p class="help-text">
          {{
            $t(
              'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_TOGGLE.HELP_TEXT'
            )
          }}
        </p>
      </label>
      <greetings-editor
        v-if="greetingEnabled"
        v-model.trim="greetingMessage"
        class="medium-12 columns"
        :label="
          $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_MESSAGE.LABEL')
        "
        :placeholder="
          $t(
            'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_MESSAGE.PLACEHOLDER'
          )
        "
        :richtext="!textAreaChannels"
      />
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
import { mapGetters } from 'vuex';
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader';
import GreetingsEditor from 'shared/components/GreetingsEditor';

export default {
  components: {
    PageHeader,
    GreetingsEditor,
  },
  data() {
    return {
      inboxName: '',
      channelWebsiteUrl: '',
      channelWidgetColor: '#009CE0',
      channelWelcomeTitle: '',
      channelWelcomeTagline: '',
      greetingEnabled: false,
      greetingMessage: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
    textAreaChannels() {
      if (
        this.isATwilioChannel ||
        this.isATwitterInbox ||
        this.isAFacebookInbox
      )
        return true;
      return false;
    },
  },
  methods: {
    async createChannel() {
      const website = await this.$store.dispatch(
        'inboxes/createWebsiteChannel',
        {
          name: this.inboxName,
          greeting_enabled: this.greetingEnabled,
          greeting_message: this.greetingMessage,
          channel: {
            type: 'web_widget',
            website_url: this.channelWebsiteUrl,
            widget_color: this.channelWidgetColor,
            welcome_title: this.channelWelcomeTitle,
            welcome_tagline: this.channelWelcomeTagline,
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
