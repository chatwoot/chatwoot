<template>
  <FormulateForm
    v-model="formValues"
    class="card flex flex-col flex-1 px-3.5 py-3 !mt-1 overflow-y-auto"
    @submit="onSubmit"
  >
    <template v-for="item in enabledPreChatFields">
      <!-- Show custom read-only input for phone number if already submitted -->
      <div
        v-if="item.name === 'phoneNumber' && preChatFormResponse[item.name]"
        :key="`${item.name}-submitted`"
        class="wrapper"
      >
        <div class="submitted-value rounded-lg w-full py-2 px-3">
          {{ preChatFormResponse[item.name] }}
        </div>
      </div>

      <!-- Show regular FormulateInput for other fields or when phone number not submitted -->
      <FormulateInput
        v-else-if="
          !(item.name === 'phoneNumber' && preChatFormResponse[item.name])
        "
        :key="`${item.name}-input`"
        :name="item.name"
        :type="item.type"
        :value="formValues[item.name]"
        :placeholder="getPlaceHolder(item)"
        :validation="getValidation(item)"
        :input-class="context => inputClass(context)"
        :validation-messages="{
          startsWithPlus: $t(
            'PRE_CHAT_FORM.FIELDS.PHONE_NUMBER.DIAL_CODE_VALID_ERROR'
          ),
          isValidPhoneNumber: $t(
            'PRE_CHAT_FORM.FIELDS.PHONE_NUMBER.VALID_ERROR'
          ),
          email: $t('PRE_CHAT_FORM.FIELDS.EMAIL_ADDRESS.VALID_ERROR'),
          required: $t('PRE_CHAT_FORM.REQUIRED'),
          matches: item.regex_cue
            ? item.regex_cue
            : $t('PRE_CHAT_FORM.REGEX_ERROR'),
        }"
        :has-error-in-phone-input="hasErrorInPhoneInput"
        :disabled="!!preChatFormResponse[item.name]"
      />
    </template>
    <button
      v-if="!allRequiredFieldsSubmitted"
      :style="{
        background: widgetColor,
        color: textColor,
        borderRadius: '8px',
      }"
      type="submit"
      :class="'hover:opacity-80 relative'"
      :disabled="isSubmitting"
    >
      <div
        v-if="isSubmitting"
        style="backdrop-filter: blur(2px)"
        class="absolute top-0 right-0 w-full h-full flex justify-center items-center"
      >
        <spinner size="medium" :color-scheme="'primary'" />
      </div>
      Submit
    </button>
  </FormulateForm>
</template>

<script>
import { mapGetters } from 'vuex';
import { mapActions } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import routerMixin from 'widget/mixins/routerMixin';
import darkModeMixin from 'widget/mixins/darkModeMixin';
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: {
    Spinner,
  },
  mixins: [routerMixin, darkModeMixin],
  props: {
    messageId: {
      type: Number,
      required: true,
    },
    items: {
      type: Array,
      default: () => [],
    },
    preChatFormResponse: {
      type: Object,
      required: false, // Changed from true to false
      default: () => ({}),
    },
  },
  data() {
    return {
      locale: this.$root.$i18n.locale,
      hasErrorInPhoneInput: false,
      formValues: {},
      labels: {
        emailAddress: 'EMAIL_ADDRESS',
        fullName: 'FULL_NAME',
        phoneNumber: 'PHONE_NUMBER',
      },
      isSubmitting: false,
      // items: [
      //   {
      //     name: 'phoneNumber',
      //     type: 'text',
      //     label: 'Phone number',
      //     enabled: true,
      //     required: true,
      //     placeholder: 'phoneNumber',
      //     field_type: 'standard',
      //   },
      //   {
      //     name: 'emailAddress',
      //     type: 'email',
      //     label: 'Email Id',
      //     enabled: true,
      //     required: true,
      //     placeholder: 'emailAddress',
      //     field_type: 'standard',
      //   },
      //   {
      //     name: 'fullName',
      //     type: 'text',
      //     label: 'Full name',
      //     enabled: true,
      //     required: true,
      //     placeholder: 'fullName',
      //     field_type: 'standard',
      //   },
      // ],
    };
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
      isCreating: 'conversation/getIsCreating',
      currentUser: 'contacts/getCurrentUser',
    }),
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
    preChatFields() {
      return this.items || [];
    },
    enabledPreChatFields() {
      return this.items
        .filter(field => field.enabled)
        .map(field => ({
          ...field,
          type:
            field.name === 'phoneNumber'
              ? 'phoneInput'
              : this.findFieldType(field.type),
        }));
    },
    inputStyles() {
      return `border rounded-lg w-full py-2 px-3 text-slate-700 outline-none`;
    },
    isInputDarkOrLightMode() {
      return `${this.$dm('bg-white', 'dark:bg-slate-600')} ${this.$dm(
        'text-slate-700',
        'dark:text-slate-50'
      )}`;
    },
    inputBorderColor() {
      return `${this.$dm('border-black-200', 'dark:border-black-500')}`;
    },
    allRequiredFieldsSubmitted() {
      const requiredFields = this.enabledPreChatFields.filter(
        field => field.required && field.enabled
      );
      return requiredFields.every(
        field =>
          this.preChatFormResponse[field.name] &&
          this.preChatFormResponse[field.name].trim() !== ''
      );
    },
  },
  mounted() {
    this.initializeFormValues();
  },
  methods: {
    ...mapActions('conversation', ['sendMessage']),
    initializeFormValues() {
      this.formValues = {
        emailAddress: this.preChatFormResponse?.emailAddress || '',
        fullName: this.preChatFormResponse?.fullName || '',
        phoneNumber: this.preChatFormResponse?.phoneNumber || '',
      };
    },
    inputClass(context) {
      const { hasErrors, classification, type } = context;
      if (classification === 'box' && type === 'checkbox') {
        return '';
      }
      if (type === 'phoneInput') {
        this.hasErrorInPhoneInput = hasErrors;
      }
      if (!hasErrors) {
        return `${this.inputStyles} hover:border-black-300 focus:border-black-300 ${this.isInputDarkOrLightMode} ${this.inputBorderColor}`;
      }
      return `${this.inputStyles} border-red-200 hover:border-red-300 focus:border-red-300 ${this.isInputDarkOrLightMode}`;
    },
    isContactFieldRequired(field) {
      return this.preChatFields.find(option => option.name === field).required;
    },
    getPlaceHolder({ name }) {
      switch (name) {
        case 'emailAddress':
          return 'Email Address';
        case 'fullName':
          return 'Full Name';

        case 'phoneNumber':
          return 'Phone Number';

        default:
          return '';
      }
    },
    getValidation({ type, name, field_type }) {
      const validations = {
        emailAddress: 'email',
        phoneNumber: ['startsWithPlus', 'isValidPhoneNumber'],
        url: 'url',
        date: 'date',
        text: null,
        select: null,
        number: null,
        checkbox: false,
      };
      const validationKeys = Object.keys(validations);
      const isRequired = this.isContactFieldRequired(name);
      const validation = isRequired
        ? ['bail', 'required']
        : ['bail', 'optional'];

      if (
        validationKeys.includes(name) ||
        validationKeys.includes(type) ||
        validationKeys.includes(field_type)
      ) {
        const validationType =
          validations[type] || validations[name] || validations[field_type];
        return validationType ? validation.concat(validationType) : validation;
      }

      return [];
    },
    findFieldType(type) {
      if (type === 'link') {
        return 'url';
      }
      if (type === 'list') {
        return 'select';
      }

      return type;
    },
    async onSubmit() {
      const { emailAddress, fullName, phoneNumber } = this.formValues;

      this.isSubmitting = true;

      try {
        await this.$store.dispatch('contacts/update', {
          user: {
            email: emailAddress,
            name: fullName,
            phone_number: phoneNumber,
          },
        });

        await this.$store.dispatch('message/update', {
          messageId: this.messageId,
          preChatFormResponse: {
            emailAddress,
            fullName,
            phoneNumber,
          },
        });

        await this.sendMessage({
          content: 'Submit',
          preChatFormResponse: {
            emailAddress,
            fullName,
            phoneNumber,
          },
          replyTo: this.messageId,
        });
      } catch (error) {
        // Ignore error
      } finally {
        this.isSubmitting = false;
      }
    },
  },
};
</script>
<style lang="scss" scoped>
@import '~widget/assets/scss/variables.scss';
::v-deep {
  .wrapper {
    margin-bottom: 1rem !important;
    .submitted-value {
      width: 100%;
      padding: 0.5rem 0.75rem;
      background-color: mix($black, $white, 5%);
      cursor: not-allowed;
      border: 1px solid rgb(215, 219, 223);

      &:hover {
        border: $base-border;
      }
    }
    .formulate-input-element--email input,
    .formulate-input-element--text input {
      &:disabled {
        background-color: mix($black, $white, 5%);
        cursor: not-allowed;

        &:hover {
          border: $base-border;
        }
      }
    }
  }
  .wrapper[data-type='checkbox'] {
    .formulate-input-wrapper {
      display: flex;
      align-items: center;
      line-height: $space-normal;

      label {
        margin-left: 0.2rem;
      }
    }
  }
  @media (prefers-color-scheme: dark) {
    .wrapper {
      .formulate-input-element--date,
      .formulate-input-element--checkbox {
        input {
          color-scheme: dark;
        }
      }
    }
  }
  .wrapper[data-type='textarea'] {
    .formulate-input-element--textarea {
      textarea {
        min-height: 8rem;
      }
    }
  }
  .pre-chat-header-message {
    .link {
      color: $color-woot;
      text-decoration: underline;
    }
  }
}
.card {
  box-shadow:
    0 0.25rem 6px rgba(50, 50, 93, 0.08),
    0 1px 3px rgba(0, 0, 0, 0.05);
  border: 1px solid rgb(240, 240, 240);
  border-radius: 8px;
  color: #3c4858;
  font-size: 0.875rem;
  line-height: 1.5;
  max-width: 100%;
  width: 300px;
  display: flex;
  flex-direction: column;
  background-color: #fff;
}

button {
  width: 100%;
  margin-left: auto;
  align-self: flex-end;
  box-shadow: 0px 1px 0px 0px #0000000d;
  border-radius: 8px;
  padding: 8px 16px 8px 16px;
  color: #fff;
  font-size: 14px;
  font-weight: 600;
  border: none;
}

button:disabled {
  cursor: not-allowed;
}
</style>
