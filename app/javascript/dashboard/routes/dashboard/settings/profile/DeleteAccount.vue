<script>
import { required } from '@vuelidate/validators';
import { mapGetters } from 'vuex';
import WootSubmitButton from '../../../../components/buttons/FormSubmitButton.vue';
import Modal from '../../../../components/Modal.vue';
import { frontendURL } from '../../../../helper/URLHelper';

export default {
  components: {
    WootSubmitButton,
    Modal,
  },
  props: {
    onClose: {
      type: Function,
      required: true,
    },
  },
  data() {
    return {
      email: '',
      isDeleting: false,
      show: true,
      redirectUrl: frontendURL('login'),
    };
  },
  validations: {
    email: {
      required,
    },
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
    }),
    deleteMessage() {
      return this.$t('PROFILE_SETTINGS.FORM.ACCOUNT_DELETE.CONFIRM.MESSAGE');
    },
    emailError() {
      return !this.validEmail(this.email) && this.emailTouched;
    },
    emailInvalid() {
      return this.emailError || this.isDeleting;
    },
  },
  methods: {
    validEmail(value) {
      return (
        value.trim().toLowerCase() === this.currentUser.email.toLowerCase()
      );
    },
    validateEmail() {
      this.emailTouched = true;
    },
    async confirmDeletion() {
      if (!this.validEmail(this.email)) {
        return;
      }

      this.isDeleting = true;

      try {
        await this.$store.dispatch('deleteAccount', {
          email: this.email,
        });
        this.onClose();
        window.location = this.redirectUrl;
        this.showAlert(
          this.$t('PROFILE_SETTINGS.FORM.ACCOUNT_DELETE.API.SUCCESS_MESSAGE')
        );
      } catch (error) {
        this.showAlert(
          this.$t('PROFILE_SETTINGS.FORM.ACCOUNT_DELETE.API.ERROR_MESSAGE')
        );
      } finally {
        this.isDeleting = false;
      }
    },
    showAlert(message) {
      this.$bus.$emit('newToastMessage', message);
    },
  },
};
</script>

<template>
  <modal :show.sync="show" :on-close="onClose">
    <div class="column content-box">
      <woot-modal-header
        :header-title="$t('PROFILE_SETTINGS.FORM.ACCOUNT_DELETE.CONFIRM.TITLE')"
      />
      <form class="row medium-8" @submit.prevent="confirmDeletion">
        <div class="medium-12 columns">
          <label :class="{ error: emailError }">
            {{ deleteMessage }}
            <input
              v-model.trim="email"
              type="text"
              :placeholder="
                $t('PROFILE_SETTINGS.FORM.ACCOUNT_DELETE.CONFIRM.PLACEHOLDER')
              "
              @input="validateEmail"
            />
            <span v-if="emailError" class="message">
              {{
                $t('PROFILE_SETTINGS.FORM.ACCOUNT_DELETE.CONFIRM.EMAIL_ERROR')
              }}
            </span>
          </label>
        </div>

        <div class="medium-12 modal-footer">
          <div class="medium-6 columns">
            <woot-submit-button
              button-class="alert button nice"
              :disabled="emailInvalid || isDeleting"
              :loading="isDeleting"
              :button-text="
                $t('PROFILE_SETTINGS.FORM.ACCOUNT_DELETE.CONFIRM.YES')
              "
            />
            <button class="button clear" @click.prevent="onClose">
              {{ $t('PROFILE_SETTINGS.FORM.ACCOUNT_DELETE.CONFIRM.NO') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </modal>
</template>