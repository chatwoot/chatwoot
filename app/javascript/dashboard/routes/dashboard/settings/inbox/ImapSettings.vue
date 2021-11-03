<template>
  <div class="settings--content">
    <settings-section
      :title="$t('INBOX_MGMT.IMAP.TITLE')"
      :sub-title="$t('INBOX_MGMT.IMAP.SUBTITLE')"
    >
      <form @submit.prevent="updateInbox">
        <label for="toggle-imap-enable">
          <input
            v-model="isIMAPEnabled"
            type="checkbox"
            name="toggle-imap-enable"
          />
          {{ $t('INBOX_MGMT.IMAP.TOGGLE_AVAILABILITY') }}
        </label>
        <p>{{ $t('INBOX_MGMT.IMAP.TOGGLE_HELP') }}</p>
        <div v-if="isIMAPEnabled" class="imap-details-wrap">
          <woot-input
            v-model.trim="address"
            :class="{ error: $v.address.$error }"
            class="medium-9 columns"
            :label="$t('INBOX_MGMT.IMAP.ADDRESS.LABEL')"
            :placeholder="$t('INBOX_MGMT.IMAP.ADDRESS.PLACE_HOLDER')"
            @blur="$v.address.$touch"
          />
          <woot-input
            v-model="port"
            type="number"
            :class="{ error: $v.port.$error }"
            class="medium-9 columns"
            :label="$t('INBOX_MGMT.IMAP.PORT.LABEL')"
            :placeholder="$t('INBOX_MGMT.IMAP.PORT.PLACE_HOLDER')"
            @blur="$v.port.$touch"
          />
          <woot-input
            v-model="email"
            :class="{ error: $v.email.$error }"
            class="medium-9 columns"
            :label="$t('INBOX_MGMT.IMAP.EMAIL.LABEL')"
            :placeholder="$t('INBOX_MGMT.IMAP.EMAIL.PLACE_HOLDER')"
            @blur="$v.email.$touch"
          />
          <woot-input
            v-model="password"
            :class="{ error: $v.password.$error }"
            class="medium-9 columns"
            :label="$t('INBOX_MGMT.IMAP.PASSWORD.LABEL')"
            :placeholder="$t('INBOX_MGMT.IMAP.PASSWORD.PLACE_HOLDER')"
            type="password"
            @blur="$v.password.$touch"
          />
          <label for="toggle-enable-ssl">
            <input
              v-model="isSSLEnabled"
              type="checkbox"
              name="toggle-enable-ssl"
            />
            {{ $t('INBOX_MGMT.IMAP.ENABLE_SSL') }}
          </label>
        </div>
        <woot-submit-button
          :button-text="$t('INBOX_MGMT.IMAP.UPDATE')"
          :loading="uiFlags.isUpdatingInbox"
          :disabled="($v.$invalid && isIMAPEnabled) || uiFlags.isUpdatingIMAP"
        />
      </form>
    </settings-section>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import SettingsSection from 'dashboard/components/SettingsSection';
import { required, minLength, email } from 'vuelidate/lib/validators';

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
      address: '',
      port: '',
      email: '',
      password: '',
      isSSLEnabled: true,
    };
  },
  validations: {
    address: { required },
    port: { required, minLength: minLength(2) },
    email: { required, email },
    password: { required },
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
        imap_enabled,
        imap_address,
        imap_port,
        imap_email,
        imap_password,
        imap_enable_ssl,
      } = this.inbox;
      this.isIMAPEnabled = imap_enabled;
      this.address = imap_address;
      this.port = imap_port;
      this.email = imap_email;
      this.password = imap_password;
      this.isSSLEnabled = imap_enable_ssl;
    },
    async updateInbox() {
      try {
        this.loading = true;
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            imap_enabled: this.isIMAPEnabled,
            imap_address: this.address,
            imap_port: this.port,
            imap_email: this.email,
            imap_password: this.password,
            imap_enable_ssl: this.isSSLEnabled,
            imap_inbox_synced_at: this.isIMAPEnabled
              ? new Date().toISOString()
              : undefined,
          },
        };
        await this.$store.dispatch('inboxes/updateInboxIMAP', payload);
        this.showAlert(this.$t('INBOX_MGMT.IMAP.EDIT.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('INBOX_MGMT.IMAP.EDIT.ERROR_MESSAGE'));
      }
    },
  },
};
</script>
<style lang="scss" scoped>
.imap-details-wrap {
  margin-bottom: var(--space-medium);
}
</style>
