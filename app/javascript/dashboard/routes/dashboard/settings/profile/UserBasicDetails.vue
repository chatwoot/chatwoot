<template>
  <form class="flex flex-col gap-4" @submit.prevent="updateUser('profile')">
    <woot-input
      v-model="userName"
      :styles="inputStyles"
      :class="{ error: $v.userName.$error }"
      :label="$t('PROFILE_SETTINGS.FORM.NAME.LABEL')"
      :placeholder="$t('PROFILE_SETTINGS.FORM.NAME.PLACEHOLDER')"
      :error="`${
        $v.userName.$error ? $t('PROFILE_SETTINGS.FORM.NAME.ERROR') : ''
      }`"
      @input="$v.userName.$touch"
    />
    <woot-input
      v-model="userDisplayName"
      :styles="inputStyles"
      :class="{ error: $v.userDisplayName.$error }"
      :label="$t('PROFILE_SETTINGS.FORM.DISPLAY_NAME.LABEL')"
      :placeholder="$t('PROFILE_SETTINGS.FORM.DISPLAY_NAME.PLACEHOLDER')"
      :error="`${
        $v.userDisplayName.$error
          ? $t('PROFILE_SETTINGS.FORM.DISPLAY_NAME.ERROR')
          : ''
      }`"
      @input="$v.userDisplayName.$touch"
    />
    <woot-input
      v-if="emailEnabled"
      v-model="userEmail"
      :styles="inputStyles"
      :class="{ error: $v.userEmail.$error }"
      :label="$t('PROFILE_SETTINGS.FORM.EMAIL.LABEL')"
      :placeholder="$t('PROFILE_SETTINGS.FORM.EMAIL.PLACEHOLDER')"
      :error="`${
        $v.userEmail.$error ? $t('PROFILE_SETTINGS.FORM.EMAIL.ERROR') : ''
      }`"
      @input="$v.userEmail.$touch"
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
import { useAlert } from 'dashboard/composables';
import FormButton from 'v3/components/Form/Button.vue';
import { required, minLength, email } from 'vuelidate/lib/validators';
export default {
  components: {
    FormButton,
  },
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
      inputStyles: {
        borderRadius: '12px',
        padding: '6px 12px',
        fontSize: '14px',
        marginBottom: '2px',
      },
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
        useAlert(this.$t('PROFILE_SETTINGS.FORM.ERROR'));
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
