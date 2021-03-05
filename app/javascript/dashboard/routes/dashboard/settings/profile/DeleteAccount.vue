<template>
  <modal :show.sync="show" :on-close="onClose">
    <div class="column content-box">
      <woot-modal-header
        :header-title="$t('PROFILE_SETTINGS.FORM.ACCOUNT_DELETE.CONFIRM.TITLE')"
      />
      <form class="row medium-8" @submit.prevent="confirmDeletion()">
        <div class="medium-12 columns">
          <label :class="{ error: $v.email.$error || isError }">
            {{ deleteMessage() }}
            <input
              v-model.trim="email"
              type="text"
              :placeholder="
                $t('PROFILE_SETTINGS.FORM.ACCOUNT_DELETE.CONFIRM.PLACEHOLDER')
              "
              @input="$v.email.$touch"
            />
            <span v-if="$v.email.$error || isError" class="message">
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
              :disabled="$v.email.$invalid || isDeleting"
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

<script>
import { required } from 'vuelidate/lib/validators';
import { mapGetters } from 'vuex';
import WootSubmitButton from '../../../../components/buttons/FormSubmitButton';
import Modal from '../../../../components/Modal';
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
      isError: false,
      isDeleting: false,
      redirectUrl: frontendURL('login'),
      show: true,
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
  },
  methods: {
    deleteMessage() {
      return `${this.$t(
        'PROFILE_SETTINGS.FORM.ACCOUNT_DELETE.CONFIRM.MESSAGE'
      )}`;
    },
    validEmail(value) {
      return (
        value.trim().toLowerCase() === this.currentUser.email.toLowerCase()
      );
    },

    confirmDeletion() {
      this.isError = !this.validEmail(this.email);
      if (this.isError) return;

      this.isDeleting = true;
      this.deleteUser();
    },
    async deleteUser() {
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
      }
    },

    showAlert(message) {
      bus.$emit('newToastMessage', message);
    },
  },
};
</script>
