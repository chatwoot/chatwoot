<template>
  <form
    class="flex flex-1 flex-col p-6 overflow-y-auto"
    @submit.prevent="onSubmit"
  >
    <div v-if="options.preChatMessage" class="text-black-800 text-sm leading-5">
      {{ options.preChatMessage }}
    </div>
    <form-input
      v-if="options.requireEmail"
      v-model="fullName"
      class="mt-5"
      :label="$t('PRE_CHAT_FORM.FIELDS.FULL_NAME.LABEL')"
      :placeholder="$t('PRE_CHAT_FORM.FIELDS.FULL_NAME.PLACEHOLDER')"
      type="text"
      :error="
        $v.fullName.$error ? $t('PRE_CHAT_FORM.FIELDS.FULL_NAME.ERROR') : ''
      "
    />
    <form-input
      v-if="options.requireEmail"
      v-model="emailAddress"
      class="mt-5"
      :label="$t('PRE_CHAT_FORM.FIELDS.EMAIL_ADDRESS.LABEL')"
      :placeholder="$t('PRE_CHAT_FORM.FIELDS.EMAIL_ADDRESS.PLACEHOLDER')"
      type="email"
      :error="
        $v.emailAddress.$error
          ? $t('PRE_CHAT_FORM.FIELDS.EMAIL_ADDRESS.ERROR')
          : ''
      "
    />
    <form-text-area
      v-model="message"
      class="my-5"
      :label="$t('PRE_CHAT_FORM.FIELDS.MESSAGE.LABEL')"
      :placeholder="$t('PRE_CHAT_FORM.FIELDS.MESSAGE.PLACEHOLDER')"
      :error="$v.message.$error ? $t('PRE_CHAT_FORM.FIELDS.MESSAGE.ERROR') : ''"
    />
    <custom-button
      class="font-medium"
      block
      :bg-color="widgetColor"
      :text-color="textColor"
      :disabled="isCreating"
    >
      <spinner v-if="isCreating" class="p-0" />
      {{ $t('START_CONVERSATION') }}
    </custom-button>
  </form>
</template>

<script>
import CustomButton from 'shared/components/Button';
import FormInput from '../Form/Input';
import FormTextArea from '../Form/TextArea';
import Spinner from 'shared/components/Spinner';
import { mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import { required, minLength, email } from 'vuelidate/lib/validators';
export default {
  components: {
    FormInput,
    FormTextArea,
    CustomButton,
    Spinner,
  },
  props: {
    options: {
      type: Object,
      default: () => ({}),
    },
  },
  validations() {
    const identityValidations = {
      fullName: {
        required,
      },
      emailAddress: {
        required,
        email,
      },
    };

    const messageValidation = {
      message: {
        required,
        minLength: minLength(1),
      },
    };
    if (this.options.requireEmail) {
      return {
        ...identityValidations,
        ...messageValidation,
      };
    }
    return messageValidation;
  },
  data() {
    return {
      fullName: '',
      emailAddress: '',
      message: '',
    };
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
      isCreating: 'conversation/getIsCreating',
    }),
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
  },
  methods: {
    onSubmit() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      this.$store.dispatch('conversation/createConversation', {
        fullName: this.fullName,
        emailAddress: this.emailAddress,
        message: this.message,
      });
    },
  },
};
</script>
