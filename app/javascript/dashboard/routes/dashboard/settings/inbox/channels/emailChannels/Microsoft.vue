<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <settings-sub-page-header
      :header-title="$t('INBOX_MGMT.ADD.MICROSOFT.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.MICROSOFT.DESCRIPTION')"
    />
    <form
      class="microsoft--sign-in-form"
      @submit.prevent="requestAuthorization"
    >
      <woot-input
        v-model.trim="email"
        type="text"
        :placeholder="$t('INBOX_MGMT.ADD.MICROSOFT.EMAIL_PLACEHOLDER')"
        @blur="$v.email.$touch"
      />
      <woot-submit-button
        icon="brand-twitter"
        button-text="Sign in with Microsoft"
        type="submit"
        :loading="isRequestingAuthorization"
      />
    </form>
  </div>
</template>
<script>
import alertMixin from 'shared/mixins/alertMixin';
import microsoftClient from 'dashboard/api/channel/microsoftClient';
import SettingsSubPageHeader from '../../../SettingsSubPageHeader.vue';
import { required, email } from 'vuelidate/lib/validators';

export default {
  components: { SettingsSubPageHeader },
  mixins: [alertMixin],
  data() {
    return { email: '', isRequestingAuthorization: false };
  },
  validations: {
    email: { required, email },
  },
  methods: {
    async requestAuthorization() {
      try {
        this.$v.$touch();
        if (this.$v.$invalid) return;

        this.isRequestingAuthorization = true;
        const response = await microsoftClient.generateAuthorization({
          email: this.email,
        });
        const {
          data: { url },
        } = response;
        window.location.href = url;
      } catch (error) {
        this.showAlert(this.$t('INBOX_MGMT.ADD.MICROSOFT.ERROR_MESSAGE'));
      } finally {
        this.isRequestingAuthorization = false;
      }
    },
  },
};
</script>

<style scoped>
.microsoft--sign-in-form {
  @apply mt-6;
}
</style>
