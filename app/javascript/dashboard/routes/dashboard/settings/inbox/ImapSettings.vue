<template>
  <div class="mx-8">
    <settings-section
      :title="$t('INBOX_MGMT.IMAP.TITLE')"
      :sub-title="$t('INBOX_MGMT.IMAP.SUBTITLE')"
      :note="$t('INBOX_MGMT.IMAP.NOTE_TEXT')"
    >
      <form @submit.prevent="updateInbox">
        <label for="toggle-imap-enable">
          <input
            v-model="isIMAPEnabled"
            type="checkbox"
            class="ltr:mr-2 rtl:ml-2"
            name="toggle-imap-enable"
          />
          {{ $t('INBOX_MGMT.IMAP.TOGGLE_AVAILABILITY') }}
        </label>
        <p>{{ $t('INBOX_MGMT.IMAP.TOGGLE_HELP') }}</p>
        <div v-if="isIMAPEnabled" class="mb-6">
          <woot-input
            v-model.trim="address"
            :class="{ error: $v.address.$error }"
            class="max-w-[75%] w-full"
            :label="$t('INBOX_MGMT.IMAP.ADDRESS.LABEL')"
            :placeholder="$t('INBOX_MGMT.IMAP.ADDRESS.PLACE_HOLDER')"
            @blur="$v.address.$touch"
          />
          <woot-input
            v-model="port"
            type="number"
            :class="{ error: $v.port.$error }"
            class="max-w-[75%] w-full"
            :label="$t('INBOX_MGMT.IMAP.PORT.LABEL')"
            :placeholder="$t('INBOX_MGMT.IMAP.PORT.PLACE_HOLDER')"
            @blur="$v.port.$touch"
          />
          <woot-input
            v-model="login"
            :class="{ error: $v.login.$error }"
            class="max-w-[75%] w-full"
            :label="$t('INBOX_MGMT.IMAP.LOGIN.LABEL')"
            :placeholder="$t('INBOX_MGMT.IMAP.LOGIN.PLACE_HOLDER')"
            @blur="$v.login.$touch"
          />
          <woot-input
            v-model="password"
            :class="{ error: $v.password.$error }"
            class="max-w-[75%] w-full"
            :label="$t('INBOX_MGMT.IMAP.PASSWORD.LABEL')"
            :placeholder="$t('INBOX_MGMT.IMAP.PASSWORD.PLACE_HOLDER')"
            type="password"
            @blur="$v.password.$touch"
          />
          <label for="toggle-enable-ssl">
            <input
              v-model="isSSLEnabled"
              type="checkbox"
              class="ltr:mr-2 rtl:ml-2"
              name="toggle-enable-ssl"
            />
            {{ $t('INBOX_MGMT.IMAP.ENABLE_SSL') }}
          </label>
        </div>
        <woot-submit-button
          :button-text="$t('INBOX_MGMT.IMAP.UPDATE')"
          :loading="uiFlags.isUpdatingIMAP"
          :disabled="($v.$invalid && isIMAPEnabled) || uiFlags.isUpdatingIMAP"
        />
      </form>
    </settings-section>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import { required, minLength } from 'vuelidate/lib/validators';

export default {
  components: {
    SettingsSection,
  },
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
      login: '',
      password: '',
      isSSLEnabled: true,
    };
  },
  validations: {
    address: { required },
    port: { required, minLength: minLength(2) },
    login: { required },
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
        imap_login,
        imap_password,
        imap_enable_ssl,
      } = this.inbox;
      this.isIMAPEnabled = imap_enabled;
      this.address = imap_address;
      this.port = imap_port;
      this.login = imap_login;
      this.password = imap_password;
      this.isSSLEnabled = imap_enable_ssl;
    },
    async updateInbox() {
      try {
        this.loading = true;
        let payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            imap_enabled: this.isIMAPEnabled,
            imap_address: this.address,
            imap_port: this.port,
            imap_login: this.login,
            imap_password: this.password,
            imap_enable_ssl: this.isSSLEnabled,
          },
        };

        if (!this.isIMAPEnabled) {
          payload.channel.smtp_enabled = false;
        }

        await this.$store.dispatch('inboxes/updateInboxIMAP', payload);
        useAlert(this.$t('INBOX_MGMT.IMAP.EDIT.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(error.message);
      }
    },
  },
};
</script>
