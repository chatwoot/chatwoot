<template>
  <FormulateForm
    v-model="formValues"
    class="flex flex-1 flex-col p-6 overflow-y-auto"
    @submit="onSubmit"
  >
    <div
      v-if="shouldShowHeaderMessage"
      class="mb-4 text-sm leading-5"
      :class="$dm('text-black-800', 'dark:text-slate-50')"
    >
      {{ headerMessage }}
    </div>
    <FormulateInput
      v-for="item in enabledPreChatFields"
      :key="item.name"
      :name="item.name"
      :type="item.type"
      :label="getLabel(item)"
      :placeholder="getPlaceHolder(item)"
      :validation="getValidation(item)"
      :options="getOptions(item)"
      :label-class="context => labelClass(context)"
      :input-class="context => inputClass(context)"
      :validation-messages="{
        isPhoneE164OrEmpty: $t('PRE_CHAT_FORM.FIELDS.PHONE_NUMBER.VALID_ERROR'),
        email: $t('PRE_CHAT_FORM.FIELDS.EMAIL_ADDRESS.VALID_ERROR'),
        required: getRequiredErrorMessage(item),
      }"
    />
    <FormulateInput
      v-if="!hasActiveCampaign"
      name="message"
      type="textarea"
      :label-class="context => labelClass(context)"
      :input-class="context => inputClass(context)"
      :label="$t('PRE_CHAT_FORM.FIELDS.MESSAGE.LABEL')"
      :placeholder="$t('PRE_CHAT_FORM.FIELDS.MESSAGE.PLACEHOLDER')"
      validation="required"
    />

    <custom-button
      class="font-medium my-5"
      block
      :bg-color="widgetColor"
      :text-color="textColor"
      :disabled="isCreating"
    >
      <spinner v-if="isCreating" class="p-0" />
      {{ $t('START_CONVERSATION') }}
    </custom-button>
  </FormulateForm>
</template>

<script>
import CustomButton from 'shared/components/Button';
import Spinner from 'shared/components/Spinner';
import { mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';

import { isEmptyObject } from 'widget/helpers/utils';
import routerMixin from 'widget/mixins/routerMixin';
import darkModeMixin from 'widget/mixins/darkModeMixin';
export default {
  components: {
    CustomButton,
    Spinner,
  },
  mixins: [routerMixin, darkModeMixin],
  props: {
    options: {
      type: Object,
      default: () => {},
    },
    disableContactFields: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      locale: this.$root.$i18n.locale,
      message: '',
      formValues: {},
      labels: {
        emailAddress: 'EMAIL_ADDRESS',
        fullName: 'FULL_NAME',
        phoneNumber: 'PHONE_NUMBER',
      },
    };
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
      isCreating: 'conversation/getIsCreating',
      activeCampaign: 'campaign/getActiveCampaign',
      currentUser: 'contacts/getCurrentUser',
    }),
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
    hasActiveCampaign() {
      return !isEmptyObject(this.activeCampaign);
    },
    shouldShowHeaderMessage() {
      return this.hasActiveCampaign || this.options.preChatMessage;
    },
    headerMessage() {
      if (this.hasActiveCampaign) {
        return this.$t('PRE_CHAT_FORM.CAMPAIGN_HEADER');
      }
      return this.options.preChatMessage;
    },
    preChatFields() {
      return this.disableContactFields ? [] : this.options.preChatFields;
    },
    filteredPreChatFields() {
      const isUserEmailAvailable = !!this.currentUser.email;
      const isUserPhoneNumberAvailable = !!this.currentUser.phone_number;
      const isUserIdentifierAvailable = !!this.currentUser.identifier;
      const isUserNameAvailable = !!(
        isUserIdentifierAvailable ||
        isUserEmailAvailable ||
        isUserPhoneNumberAvailable
      );
      return this.preChatFields.filter(field => {
        if (isUserEmailAvailable && field.name === 'emailAddress') {
          return false;
        }
        if (isUserPhoneNumberAvailable && field.name === 'phoneNumber') {
          return false;
        }
        if (isUserNameAvailable && field.name === 'fullName') {
          return false;
        }
        return true;
      });
    },
    enabledPreChatFields() {
      return this.filteredPreChatFields
        .filter(field => field.enabled)
        .map(field => ({
          ...field,
          type: this.findFieldType(field.type),
        }));
    },
    conversationCustomAttributes() {
      let conversationAttributes = {};
      this.enabledPreChatFields.forEach(field => {
        if (field.field_type === 'conversation_attribute') {
          conversationAttributes = {
            ...conversationAttributes,
            [field.name]: this.getValue(field),
          };
        }
      });
      return conversationAttributes;
    },
    contactCustomAttributes() {
      let contactAttributes = {};
      this.enabledPreChatFields.forEach(field => {
        if (field.field_type === 'contact_attribute') {
          contactAttributes = {
            ...contactAttributes,
            [field.name]: this.getValue(field),
          };
        }
      });
      return contactAttributes;
    },
    inputStyles() {
      return `mt-2 border rounded w-full py-2 px-3 text-slate-700 outline-none`;
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
  },
  methods: {
    labelClass(context) {
      const { hasErrors } = context;
      if (!hasErrors) {
        return `text-xs font-medium ${this.$dm(
          'text-black-800',
          'dark:text-slate-50'
        )}`;
      }
      return `text-xs font-medium ${this.$dm(
        'text-red-400',
        'dark:text-red-400'
      )}`;
    },
    inputClass(context) {
      const { hasErrors, classification, type } = context;
      if (classification === 'box' && type === 'checkbox') {
        return '';
      }
      if (!hasErrors) {
        return `${this.inputStyles} hover:border-black-300 focus:border-black-300 ${this.isInputDarkOrLightMode} ${this.inputBorderColor}`;
      }
      return `${this.inputStyles} border-red-200 hover:border-red-300 focus:border-red-300 ${this.isInputDarkOrLightMode}`;
    },
    isContactFieldRequired(field) {
      return this.preChatFields.find(option => option.name === field).required;
    },
    getLabel({ name, label }) {
      if (this.labels[name])
        return this.$t(`PRE_CHAT_FORM.FIELDS.${this.labels[name]}.LABEL`);
      return label;
    },
    getPlaceHolder({ name, placeholder }) {
      if (this.labels[name])
        return this.$t(`PRE_CHAT_FORM.FIELDS.${this.labels[name]}.PLACEHOLDER`);
      return placeholder;
    },
    getValue({ name, type }) {
      if (type === 'select') {
        return this.enabledPreChatFields.find(option => option.name === name)
          .values[this.formValues[name]];
      }
      return this.formValues[name] || null;
    },

    getRequiredErrorMessage({ name, label }) {
      if (this.labels[name])
        return this.$t(
          `PRE_CHAT_FORM.FIELDS.${this.labels[name]}.REQUIRED_ERROR`
        );
      return `${label} ${this.$t('PRE_CHAT_FORM.IS_REQUIRED')}`;
    },
    getValidation({ type, name }) {
      if (!this.isContactFieldRequired(name)) {
        return '';
      }
      const validations = {
        emailAddress: 'email',
        phoneNumber: 'isPhoneE164OrEmpty',
        url: 'url',
        date: 'date',
        text: null,
        select: null,
        number: null,
        checkbox: false,
      };
      const validationKeys = Object.keys(validations);
      const validation = 'bail|required';
      if (validationKeys.includes(name) || validationKeys.includes(type)) {
        const validationType = validations[type] || validations[name];
        return validationType ? `${validation}|${validationType}` : validation;
      }
      return '';
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
    getOptions(item) {
      if (item.type === 'select') {
        let values = {};
        item.values.forEach((value, index) => {
          values = {
            ...values,
            [index]: value,
          };
        });
        return values;
      }
      return null;
    },
    onSubmit() {
      const { emailAddress, fullName, phoneNumber, message } = this.formValues;
      const { email } = this.currentUser;
      this.$emit('submit', {
        fullName,
        phoneNumber,
        emailAddress: emailAddress || email,
        message,
        activeCampaignId: this.activeCampaign.id,
        conversationCustomAttributes: this.conversationCustomAttributes,
        contactCustomAttributes: this.contactCustomAttributes,
      });
    },
  },
};
</script>
<style lang="scss" scoped>
::v-deep {
  .wrapper[data-type='checkbox'] {
    .formulate-input-wrapper {
      display: flex;
      align-items: center;

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
}
</style>
