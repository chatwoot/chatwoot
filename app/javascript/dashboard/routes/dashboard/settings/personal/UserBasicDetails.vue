<template>
  <form class="flex flex-col gap-6" @submit.prevent="updateUser('profile')">
    <form-input
      v-model="userName"
      type="text"
      name="name"
      :class="{ error: $v.userName.$error }"
      :label="$t('PROFILE_SETTINGS.FORM.NAME.LABEL')"
      :placeholder="$t('PROFILE_SETTINGS.FORM.NAME.PLACEHOLDER')"
      :has-error="$v.userName.$error"
      :error-message="$t('PROFILE_SETTINGS.FORM.NAME.ERROR')"
      @blur="$v.userName.$touch"
    />
    <form-input
      v-model="userDisplayName"
      type="text"
      name="displayName"
      :class="{ error: $v.userDisplayName.$error }"
      :label="$t('PROFILE_SETTINGS.FORM.DISPLAY_NAME.LABEL')"
      :placeholder="$t('PROFILE_SETTINGS.FORM.DISPLAY_NAME.PLACEHOLDER')"
      :has-error="$v.userDisplayName.$error"
      :error-message="$t('PROFILE_SETTINGS.FORM.DISPLAY_NAME.ERROR')"
      @blur="$v.userDisplayName.$touch"
    />
    <form-input
      v-if="emailEnabled"
      v-model="userEmail"
      type="email"
      name="email"
      :class="{ error: $v.userEmail.$error }"
      :label="$t('PROFILE_SETTINGS.FORM.EMAIL.LABEL')"
      :placeholder="$t('PROFILE_SETTINGS.FORM.EMAIL.PLACEHOLDER')"
      :has-error="$v.userEmail.$error"
      :error-message="$t('PROFILE_SETTINGS.FORM.EMAIL.ERROR')"
      @blur="$v.userEmail.$touch"
    />
    <form-button
      type="submit"
      color-scheme="primary"
      variant="solid"
      size="large"
    >
      {{ $t('PROFILE_SETTINGS.BTN_TEXT') }}
    </form-button>
  </form>
</template>
<script>
import FormButton from 'v3/components/Form/Button.vue';
import FormInput from 'v3/components/Form/Input.vue';
import { required, minLength, email } from 'vuelidate/lib/validators';
import alertMixin from 'shared/mixins/alertMixin';
export default {
  components: {
    FormButton,
    FormInput,
  },
  mixins: [alertMixin],
  props: {
    name: {
      type: String,
      default: '',
    },
    email: {
      type: String,
      default: '',
    },
    displayName: {
      type: String,
      default: '',
    },
    emailEnabled: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      userName: this.name,
      userDisplayName: this.displayName,
      userEmail: this.email,
    };
  },
  validations: {
    userName: {
      required,
      minLength: minLength(1),
    },
    userDisplayName: {},
    userEmail: {
      required,
      email,
    },
  },
  watch: {
    name: {
      handler(value) {
        this.userName = value;
      },
      immediate: true,
    },
    displayName: {
      handler(value) {
        this.userDisplayName = value;
      },
      immediate: true,
    },
    email: {
      handler(value) {
        this.userEmail = value;
      },
      immediate: true,
    },
  },
  methods: {
    async updateUser() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        this.showAlert(this.$t('PROFILE_SETTINGS.FORM.ERROR'));
        return;
      }
      this.$emit('update-user', {
        name: this.userName,
        displayName: this.userDisplayName,
        email: this.userEmail,
      });
    },
  },
};
</script>
