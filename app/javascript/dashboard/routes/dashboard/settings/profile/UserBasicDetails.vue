<script>
import { useAlert } from 'dashboard/composables';
import FormButton from 'v3/components/Form/Button.vue';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, email } from '@vuelidate/validators';
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
    azarDisplayName: {
      type: String,
      default: '',
    },
    monoDisplayName: {
      type: String,
      default: '',
    },
    gbitsDisplayName: {
      type: String,
      default: '',
    },
    emailEnabled: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['updateUser'],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      userName: this.name,
      userDisplayName: this.displayName,
      azarDisplayName: this.azarDisplayName,
      monoDisplayName: this.monoDisplayName,
      gbitsDisplayName: this.gbitsDisplayName,
      userEmail: this.email,
      inputStyles: {
        borderRadius: '0.75rem',
        padding: '0.375rem 0.75rem',
        fontSize: '0.875rem',
        marginBottom: '0.125rem',
      },
    };
  },
  validations: {
    userName: {
      required,
      minLength: minLength(1),
    },
    userDisplayName: {},
    azarDisplayName: {},
    monoDisplayName: {},
    gbitsDisplayName: {},
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
    azarDisplayName: {
      handler(value) {
        this.azarDisplayName = value;
      },
      immediate: true,
    },
    monoDisplayName: {
      handler(value) {
        this.monoDisplayName = value;
      },
      immediate: true,
    },
    gbitsDisplayName: {
      handler(value) {
        this.gbitsDisplayName = value;
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
      this.v$.$touch();
      if (this.v$.$invalid) {
        useAlert(this.$t('PROFILE_SETTINGS.FORM.ERROR'));
        return;
      }
      this.$emit('updateUser', {
        name: this.userName,
        displayName: this.userDisplayName,
        azarDisplayName: this.azarDisplayName,
        monoDisplayName: this.monoDisplayName,
        gbitsDisplayName: this.gbitsDisplayName,
        email: this.userEmail,
      });
    },
  },
};
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="updateUser('profile')">
    <woot-input
      v-model="userName"
      :styles="inputStyles"
      :class="{ error: v$.userName.$error }"
      :label="$t('PROFILE_SETTINGS.FORM.NAME.LABEL')"
      :placeholder="$t('PROFILE_SETTINGS.FORM.NAME.PLACEHOLDER')"
      :error="`${
        v$.userName.$error ? $t('PROFILE_SETTINGS.FORM.NAME.ERROR') : ''
      }`"
      @input="v$.userName.$touch"
      @blur="v$.userName.$touch"
    />
    <woot-input
      v-model="userDisplayName"
      :styles="inputStyles"
      :class="{ error: v$.userDisplayName.$error }"
      :label="$t('PROFILE_SETTINGS.FORM.DISPLAY_NAME.LABEL')"
      :placeholder="$t('PROFILE_SETTINGS.FORM.DISPLAY_NAME.PLACEHOLDER')"
      :error="`${
        v$.userDisplayName.$error
          ? $t('PROFILE_SETTINGS.FORM.DISPLAY_NAME.ERROR')
          : ''
      }`"
      @input="v$.userDisplayName.$touch"
      @blur="v$.userDisplayName.$touch"
    />

    <woot-input
      v-model="azarDisplayName"
      :styles="inputStyles"
      :class="{ error: v$.azarDisplayName.$error }"
      :label="$t('PROFILE_SETTINGS.FORM.AZAR_DISPLAY_NAME.LABEL')"
      :placeholder="$t('PROFILE_SETTINGS.FORM.AZAR_DISPLAY_NAME.PLACEHOLDER')"
      :error="`${
        v$.azarDisplayName.$error
          ? $t('PROFILE_SETTINGS.FORM.AZAR_DISPLAY_NAME.ERROR')
          : ''
      }`"
      @input="v$.azarDisplayName.$touch"
      @blur="v$.azarDisplayName.$touch"
    />

    <woot-input
      v-model="monoDisplayName"
      :styles="inputStyles"
      :class="{ error: v$.monoDisplayName.$error }"
      :label="$t('PROFILE_SETTINGS.FORM.MONO_DISPLAY_NAME.LABEL')"
      :placeholder="$t('PROFILE_SETTINGS.FORM.MONO_DISPLAY_NAME.PLACEHOLDER')"
      :error="`${
        v$.monoDisplayName.$error
          ? $t('PROFILE_SETTINGS.FORM.MONO_DISPLAY_NAME.ERROR')
          : ''
      }`"
      @input="v$.monoDisplayName.$touch"
      @blur="v$.monoDisplayName.$touch"
    />

    <woot-input
      v-model="gbitsDisplayName"
      :styles="inputStyles"
      :class="{ error: v$.gbitsDisplayName.$error }"
      :label="$t('PROFILE_SETTINGS.FORM.GBITS_DISPLAY_NAME.LABEL')"
      :placeholder="$t('PROFILE_SETTINGS.FORM.GBITS_DISPLAY_NAME.PLACEHOLDER')"
      :error="`${
        v$.gbitsDisplayName.$error
          ? $t('PROFILE_SETTINGS.FORM.GBITS_DISPLAY_NAME.ERROR')
          : ''
      }`"
      @input="v$.gbitsDisplayName.$touch"
      @blur="v$.gbitsDisplayName.$touch"
    />

    <woot-input
      v-if="emailEnabled"
      v-model="userEmail"
      :styles="inputStyles"
      :class="{ error: v$.userEmail.$error }"
      :label="$t('PROFILE_SETTINGS.FORM.EMAIL.LABEL')"
      :placeholder="$t('PROFILE_SETTINGS.FORM.EMAIL.PLACEHOLDER')"
      :error="`${
        v$.userEmail.$error ? $t('PROFILE_SETTINGS.FORM.EMAIL.ERROR') : ''
      }`"
      @input="v$.userEmail.$touch"
      @blur="v$.userEmail.$touch"
    />
    <FormButton
      type="submit"
      color-scheme="primary"
      variant="solid"
      size="large"
    >
      {{ $t('PROFILE_SETTINGS.BTN_TEXT') }}
    </FormButton>
  </form>
</template>
