<script>
import { useAlert } from 'dashboard/composables';
import SettingsFieldSection from 'dashboard/components-next/Settings/SettingsFieldSection.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    SettingsFieldSection,
    NextButton,
  },
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      isEnabled: false,
      loading: false,
    };
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
      this.isEnabled = Boolean(this.inbox.continue_open_conversation);
    },
    async updateInbox() {
      try {
        this.loading = true;
        await this.$store.dispatch('inboxes/updateInbox', {
          id: this.inbox.id,
          formData: false,
          channel: {
            continue_open_conversation: this.isEnabled,
          },
        });
        useAlert(
          this.$t('INBOX_MGMT.CONVERSATION_CONTINUITY.EDIT.SUCCESS_MESSAGE')
        );
      } catch (error) {
        useAlert(error.message);
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>

<template>
  <SettingsFieldSection
    :label="$t('INBOX_MGMT.CONVERSATION_CONTINUITY.TITLE')"
    :help-text="$t('INBOX_MGMT.CONVERSATION_CONTINUITY.NOTE_TEXT')"
    class="[&>div]:!items-start [&>div>label]:mt-1 mb-4"
  >
    <form @submit.prevent="updateInbox">
      <label for="toggle-continue-open-conversation">
        <input
          v-model="isEnabled"
          type="checkbox"
          class="ltr:mr-1 rtl:ml-1"
          name="toggle-continue-open-conversation"
        />
        {{ $t('INBOX_MGMT.CONVERSATION_CONTINUITY.TOGGLE_AVAILABILITY') }}
      </label>
      <p>{{ $t('INBOX_MGMT.CONVERSATION_CONTINUITY.TOGGLE_HELP') }}</p>
      <NextButton
        type="submit"
        :label="$t('INBOX_MGMT.CONVERSATION_CONTINUITY.EDIT.BUTTON_TEXT')"
        :is-loading="loading"
      />
    </form>
  </SettingsFieldSection>
</template>
