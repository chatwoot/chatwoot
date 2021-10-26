<template>
  <div class="settings--content">
    <settings-section
      :title="$t('INBOX_MGMT.IMAP.TITLE')"
      :sub-title="$t('INBOX_MGMT.IMAP.SUBTITLE')"
    >
      <form @submit.prevent="updateInbox">
        <label for="toggle-business-hours" class="toggle-input-wrap">
          <input
            v-model="isIMAPEnabled"
            type="checkbox"
            name="toggle-business-hours"
          />
          {{ $t('INBOX_MGMT.IMAP.TOGGLE_AVAILABILITY') }}
        </label>
        <p>{{ $t('INBOX_MGMT.IMAP.TOGGLE_HELP') }}</p>
        <div v-if="isIMAPEnabled" class="business-hours-wrap">
          <woot-input
            v-model.trim="host"
            class="medium-9 columns"
            label="Hostname"
            placeholder="Hostname"
          />
          <woot-input
            v-model="port"
            class="medium-9 columns"
            label="Port"
            placeholder="Port"
          />
          <woot-input
            v-model="user_email"
            class="medium-9 columns"
            label="Email"
            placeholder="Email"
          />
          <woot-input
            v-model="user_password"
            class="medium-9 columns"
            label="Password"
            placeholder="Password"
          />
        </div>
        <woot-submit-button
          :button-text="$t('INBOX_MGMT.IMAP.UPDATE')"
          :loading="uiFlags.isUpdatingInbox"
        />
      </form>
    </settings-section>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import SettingsSection from 'dashboard/components/SettingsSection';
import { required } from 'vuelidate/lib/validators';

export default {
  components: {
    SettingsSection,
  },
  mixins: [alertMixin],
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      isIMAPEnabled: false,
      host: '',
      port: '',
      user_email: '',
      user_password: '',
    };
  },
  validations: {
    host: {
      required,
    },
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
    console.log(this.inbox);
    this.setDefaults();
  },
  methods: {
    setDefaults() {
      const {
        imap_enabled,
        host,
        port,
        user_email,
        user_password,
      } = this.inbox;
      this.isIMAPEnabled = imap_enabled;
      this.host = host;
      this.port = port;
      this.user_email = user_email;
      this.user_password = user_password;
    },
    async updateInbox() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            imap_enabled: this.isIMAPEnabled,
            host: this.host,
            port: this.port,
            user_email: this.user_email,
            user_password: this.user_password,
          },
        };
        console.log(payload);
        await this.$store.dispatch('inboxes/updateInbox', payload);
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      }
    },
  },
};
</script>
<style lang="scss" scoped>
.timezone-input-wrap {
  max-width: 60rem;

  &::v-deep .multiselect {
    margin-top: var(--space-small);
  }
}

.unavailable-input-wrap {
  max-width: 60rem;

  textarea {
    min-height: var(--space-jumbo);
    margin-top: var(--space-small);
  }
}

.business-hours-wrap {
  margin-bottom: var(--space-medium);
}
</style>
