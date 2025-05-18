<script>
import PageHeader from '../../SettingsSubPageHeader.vue';
import { useAlert } from 'dashboard/composables';

export default {
  components: { PageHeader },
  data() {
    return {
      phone_number: '',
      instance_id: '',
      token: '',
      api_url: 'https://api.z-api.io',
      name: 'WhatsApp Z-API',
      security_token: '',
    };
  },
  methods: {
    async createChannel() {
      try {
        await this.$store.dispatch('inboxes/createWhatsappZapiChannel', {
          phone_number: this.phone_number,
          instance_id: this.instance_id,
          token: this.token,
          api_url: this.api_url,
          name: this.name,
          security_token: this.security_token,
        });
        this.$router.push({ name: 'settings_inboxes' });
      } catch (error) {
        let message =
          error?.response?.data?.message ||
          error.message ||
          this.$t('INBOX_MGMT.ADD.WHATSAPP_ZAPI.ERROR_MESSAGE');
        useAlert(message);
      }
    },
  },
};
</script>

<template>
  <div
    class="border border-n-weak bg-n-solid-1 rounded-t-lg border-b-0 h-full w-full p-6 col-span-6 overflow-auto"
  >
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.WHATSAPP_ZAPI.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.WHATSAPP_ZAPI.DESC')"
    />
    <form class="space-y-4 max-w-lg mt-6" @submit.prevent="createChannel">
      <div>
        <label>
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_ZAPI.PHONE_NUMBER.LABEL') }}
        </label>
        <input
          v-model="phone_number"
          required
          class="input"
          :placeholder="
            $t('INBOX_MGMT.ADD.WHATSAPP_ZAPI.PHONE_NUMBER.PLACEHOLDER')
          "
        />
      </div>
      <div>
        <label>
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_ZAPI.INSTANCE_ID.LABEL') }}
        </label>
        <input
          v-model="instance_id"
          required
          class="input"
          :placeholder="
            $t('INBOX_MGMT.ADD.WHATSAPP_ZAPI.INSTANCE_ID.PLACEHOLDER')
          "
        />
      </div>
      <div>
        <label>
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_ZAPI.TOKEN.LABEL') }}
        </label>
        <input
          v-model="token"
          required
          class="input"
          :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP_ZAPI.TOKEN.PLACEHOLDER')"
        />
      </div>
      <div>
        <label>
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_ZAPI.API_URL.LABEL') }}
        </label>
        <input
          v-model="api_url"
          required
          class="input"
          :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP_ZAPI.API_URL.PLACEHOLDER')"
        />
      </div>
      <div>
        <label>
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_ZAPI.SECURITY_TOKEN.LABEL') }}
        </label>
        <input
          v-model="security_token"
          required
          class="input"
          :placeholder="
            $t('INBOX_MGMT.ADD.WHATSAPP_ZAPI.SECURITY_TOKEN.PLACEHOLDER')
          "
        />
      </div>
      <button type="submit" class="button button--primary w-full mt-4">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP_ZAPI.SUBMIT_BUTTON') }}
      </button>
    </form>
  </div>
</template>

<style scoped>
.input {
  width: 100%;
  padding: 8px;
  border: 1px solid #ccc;
  border-radius: 4px;
}
.button.primary {
  background: #25d366;
  color: #fff;
  padding: 10px 20px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}
</style>
