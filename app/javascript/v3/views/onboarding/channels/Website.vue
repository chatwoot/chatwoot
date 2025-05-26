<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import router from '../../../../dashboard/routes/index';

import PageHeader from '../../../../dashboard/routes/dashboard/settings/SettingsSubPageHeader.vue';
import GreetingsEditor from 'shared/components/GreetingsEditor.vue';

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
      channelLogoColors: { dot1: '#33a854', dot2: '#fabc05', dot3: '#ea4234' },
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
      try {
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
              logoColors: this.channelLogoColors,
              welcome_title: this.channelWelcomeTitle,
              welcome_tagline: this.channelWelcomeTagline,
            },
          }
        );
        router.replace({
          name: 'onboarding_setup_inbox_add_agents',
          params: {
            inbox_id: website.id,
          },
        });
      } catch (error) {
        useAlert(
          error.message ||
            this.$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>

<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full flex-shrink-0 flex-grow-0"
  >
    <woot-loading-state
      v-if="uiFlags.isCreating"
      :message="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.LOADING_MESSAGE')"
    />
    <form
      v-if="!uiFlags.isCreating"
      class="flex flex-wrap mx-0"
      @submit.prevent="createChannel"
    >
      <div class="w-full">
        <label>
          {{ $t('INBOX_MGMT.ADD.WEBSITE_NAME.LABEL') }}
          <input
            v-model="inboxName"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.WEBSITE_NAME.PLACEHOLDER')"
          />
        </label>
      </div>
      <div class="w-full">
        <label>
          {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_DOMAIN.LABEL') }}
          <input
            v-model="channelWebsiteUrl"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_DOMAIN.PLACEHOLDER')
            "
          />
        </label>
      </div>

      <div class="flex flex-row gap-6">
        <label>
          {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.WIDGET_COLOR.LABEL') }}
          <woot-color-picker v-model="channelWidgetColor" />
        </label>

        <div class="w-px h-20 truncate bg-n-slate-6" />

        <label class="flex flex-col pb-4">
          {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.DOT_COLOR1.LABEL') }}
          <woot-color-picker v-model="channelLogoColors['dot1']" />
        </label>
        <label class="flex flex-col pb-4">
          {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.DOT_COLOR2.LABEL') }}
          <woot-color-picker v-model="channelLogoColors['dot2']" />
        </label>
        <label class="flex flex-col pb-4">
          {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.DOT_COLOR3.LABEL') }}
          <woot-color-picker v-model="channelLogoColors['dot3']" />
        </label>
      </div>

      <div class="w-full">
        <label>
          {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TITLE.LABEL') }}
          <input
            v-model="channelWelcomeTitle"
            type="text"
            :placeholder="
              $t(
                'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TITLE.PLACEHOLDER'
              )
            "
          />
        </label>
      </div>
      <div class="w-full">
        <label>
          {{
            $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TAGLINE.LABEL')
          }}
          <input
            v-model="channelWelcomeTagline"
            type="text"
            :placeholder="
              $t(
                'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TAGLINE.PLACEHOLDER'
              )
            "
          />
        </label>
      </div>
      <label class="w-full">
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
      <GreetingsEditor
        v-if="greetingEnabled"
        v-model="greetingMessage"
        class="w-full"
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
      <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
        <div class="w-full">
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
