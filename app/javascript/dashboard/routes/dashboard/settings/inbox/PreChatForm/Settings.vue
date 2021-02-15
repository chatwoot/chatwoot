<template>
  <div class="settings--content">
    <div class="prechat--title">
      {{ $t('INBOX_MGMT.PRE_CHAT_FORM.DESCRIPTION') }}
    </div>
    <form class="medium-6" @submit.prevent="updateInbox">
      <label class="medium-9 columns">
        {{ $t('INBOX_MGMT.PRE_CHAT_FORM.ENABLE.LABEL') }}
        <select v-model="preChatFormEnabled">
          <option :value="true">
            {{ $t('INBOX_MGMT.PRE_CHAT_FORM.ENABLE.OPTIONS.ENABLED') }}
          </option>
          <option :value="false">
            {{ $t('INBOX_MGMT.PRE_CHAT_FORM.ENABLE.OPTIONS.DISABLED') }}
          </option>
        </select>
      </label>

      <label class="medium-9">
        {{ $t('INBOX_MGMT.PRE_CHAT_FORM.PRE_CHAT_MESSAGE.LABEL') }}
        <textarea
          v-model.trim="preChatMessage"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.PRE_CHAT_FORM.PRE_CHAT_MESSAGE.PLACEHOLDER')
          "
        />
      </label>
      <div>
        <input
          v-model="preChatFieldOptions"
          type="checkbox"
          value="requireEmail"
          @input="handlePreChatFieldOptions"
        />
        <label for="requireEmail">
          {{ $t('INBOX_MGMT.PRE_CHAT_FORM.REQUIRE_EMAIL.LABEL') }}
        </label>
      </div>
      <woot-submit-button
        :button-text="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
        :loading="uiFlags.isUpdatingInbox"
      />
    </form>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  mixins: [alertMixin],
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      preChatFormEnabled: false,
      preChatMessage: '',
      preChatFieldOptions: [],
    };
  },
  computed: {
    ...mapGetters({ uiFlags: 'inboxes/getUIFlags' }),
  },
  watch: {
    inbox() {
      this.setDefaults();
    },
  },
  mounted() {
    this.setDefaults();
  },
  methods: {
    setDefaults() {
      const {
        pre_chat_form_enabled: preChatFormEnabled,
        pre_chat_form_options: preChatFormOptions,
      } = this.inbox;
      this.preChatFormEnabled = preChatFormEnabled;
      const { pre_chat_message: preChatMessage, require_email: requireEmail } =
        preChatFormOptions || {};
      this.preChatMessage = preChatMessage;
      if (requireEmail) {
        this.preChatFieldOptions = ['requireEmail'];
      }
    },
    handlePreChatFieldOptions(event) {
      if (this.preChatFieldOptions.includes(event.target.value)) {
        this.preChatFieldOptions = [];
      } else {
        this.preChatFieldOptions = [event.target.value];
      }
    },
    async updateInbox() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            pre_chat_form_enabled: this.preChatFormEnabled,
            pre_chat_form_options: {
              pre_chat_message: this.preChatMessage,
              require_email: this.preChatFieldOptions.includes('requireEmail'),
            },
          },
        };
        await this.$store.dispatch('inboxes/updateInbox', payload);
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      }
    },
  },
};
</script>
<style scoped>
.settings--content {
  font-size: var(--font-size-default);
}

.prechat--title {
  margin: var(--space-medium) 0 var(--space-slab);
}
</style>
