<script>
import CustomButton from 'shared/components/Button.vue';
import Spinner from 'shared/components/Spinner.vue';
import { mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import { isEmptyObject } from 'widget/helpers/utils';
import { getRegexp } from 'shared/helpers/Validators';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import configMixin from 'widget/mixins/configMixin';
import { FormKit, createInput } from '@formkit/vue';
import PhoneInput from 'widget/components/Form/PhoneInput.vue';

export default {
  components: {
    CustomButton,
    Spinner,
    FormKit,
  },
  mixins: [configMixin],
  props: {
    options: {
      type: Object,
      default: () => {},
    },
  },
  emits: ['submitPreChat'],
  setup() {
    const phoneInput = createInput(PhoneInput, {
      props: ['hasErrorInPhoneInput'],
    });
    const { formatMessage } = useMessageFormatter();

    return { formatMessage, phoneInput };
  },
  data() {
    return {
      locale: this.$root.$i18n.locale,
      hasErrorInPhoneInput: false,
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
      isConversationRouting: 'appConfig/getIsUpdatingRoute',
      activeCampaign: 'campaign/getActiveCampaign',
      currentUser: 'contacts/getCurrentUser',
    }),
    isCreatingConversation() {
      return this.isCreating || this.isConversationRouting;
    },
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
    hasActiveCampaign() {
      return !isEmptyObject(this.activeCampaign);
    },
    shouldShowHeaderMessage() {
      return (
        this.hasActiveCampaign ||
        (this.preChatFormEnabled && !!this.headerMessage)
      );
    },
    headerMessage() {
      if (this.preChatFormEnabled) {
        return this.options.preChatMessage;
      }
      if (this.hasActiveCampaign) {
        return this.$t('PRE_CHAT_FORM.CAMPAIGN_HEADER');
      }
      return '';
    },
    preChatFields() {
      return this.preChatFormEnabled ? this.options.preChatFields : [];
    },
    filteredPreChatFields() {
      const isUserEmailAvailable = this.currentUser.has_email;
      const isUserPhoneNumberAvailable = this.currentUser.has_phone_number;
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
          type:
            field.name === 'phoneNumber'
              ? this.phoneInput
              : this.findFieldType(field.type),
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
  },
  methods: {
    inputClass(input) {
      const { state, family: classification, type } = input.context;
      if (classification === 'box' && type === 'checkbox') {
        return '';
      }
      if (type === 'phoneInput') {
        this.hasErrorInPhoneInput = state.invalid;
      }
      return 'mt-1 rounded w-full py-2 px-3';
    },
    isContactFieldRequired(field) {
      return this.preChatFields.find(option => option.name === field).required;
    },
    getLabel({ label }) {
      return label;
    },
    getPlaceHolder({ placeholder }) {
      return placeholder;
    },
    getValue({ name, type }) {
      if (type === 'select') {
        return this.enabledPreChatFields.find(option => option.name === name)
          .values[this.formValues[name]];
      }
      return this.formValues[name] || null;
    },
    getValidation({ type, name, field_type, regex_pattern }) {
      const regex = regex_pattern ? getRegexp(regex_pattern) : null;
      // FormKit caches the RegExp and calls .test() across keystrokes, so
      // drop stateful g/y flags to stop lastIndex mutation flipping validity.
      const matchRegex = regex
        ? new RegExp(regex.source, regex.flags.replace(/[gy]/g, ''))
        : null;
      const validations = {
        emailAddress: 'email',
        phoneNumber: ['startsWithPlus', 'isValidPhoneNumber'],
        url: 'url',
        date: 'date',
        text: null,
        select: null,
        number: null,
        checkbox: false,
        contact_attribute: matchRegex ? [['matches', matchRegex]] : null,
        conversation_attribute: matchRegex ? [['matches', matchRegex]] : null,
      };
      const validationKeys = Object.keys(validations);
      const isRequired = this.isContactFieldRequired(name);
      const baseRules = isRequired ? [['required']] : [['optional']];

      if (
        !validationKeys.includes(name) &&
        !validationKeys.includes(type) &&
        !validationKeys.includes(field_type)
      ) {
        return '';
      }

      const validationType =
        validations[type] || validations[name] || validations[field_type];
      if (!validationType) return baseRules;

      // Normalise into array-of-arrays so RegExp objects in `['matches', regex]`
      // survive without being stringified by FormKit.
      const extraRules = Array.isArray(validationType)
        ? validationType.map(rule => (Array.isArray(rule) ? rule : [rule]))
        : [[validationType]];

      return baseRules.concat(extraRules);
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
      return {};
    },
    onSubmit() {
      const { emailAddress, fullName, phoneNumber, message } = this.formValues;
      this.$emit('submitPreChat', {
        fullName,
        phoneNumber,
        emailAddress,
        message,
        activeCampaignId: this.activeCampaign.id,
        conversationCustomAttributes: this.conversationCustomAttributes,
        contactCustomAttributes: this.contactCustomAttributes,
      });
    },
  },
};
</script>

<template>
  <!-- hide the default submit button for now -->
  <FormKit
    v-model="formValues"
    type="form"
    form-class="flex flex-col flex-1 w-full p-6 overflow-y-auto"
    :incomplete-message="false"
    :submit-attrs="{
      inputClass: 'hidden',
      wrapperClass: 'hidden',
    }"
    @submit="onSubmit"
  >
    <div
      v-if="shouldShowHeaderMessage"
      v-dompurify-html="formatMessage(headerMessage, false)"
      class="mb-4 text-base leading-5 text-n-slate-12 [&>p>.link]:text-n-blue-11 [&>p>.link]:hover:underline"
    />
    <!-- Why do the v-bind shenanigan? Because Formkit API is really bad.
    If we just pass the options as is even with null or undefined or false,
    it assumes we are trying to make a multicheckbox. This is the best we have for now -->
    <FormKit
      v-for="item in enabledPreChatFields"
      :key="item.name"
      :name="item.name"
      :type="item.type"
      :label="getLabel(item)"
      :placeholder="getPlaceHolder(item)"
      :validation="getValidation(item)"
      v-bind="
        item.type === 'select'
          ? {
              options: getOptions(item),
            }
          : undefined
      "
      label-class="text-sm font-medium text-n-slate-12"
      :input-class="context => inputClass(context)"
      :validation-messages="{
        startsWithPlus: $t(
          'PRE_CHAT_FORM.FIELDS.PHONE_NUMBER.DIAL_CODE_VALID_ERROR'
        ),
        isValidPhoneNumber: $t('PRE_CHAT_FORM.FIELDS.PHONE_NUMBER.VALID_ERROR'),
        email: $t('PRE_CHAT_FORM.FIELDS.EMAIL_ADDRESS.VALID_ERROR'),
        required: $t('PRE_CHAT_FORM.REQUIRED'),
        matches: item.regex_cue
          ? item.regex_cue
          : $t('PRE_CHAT_FORM.REGEX_ERROR'),
      }"
      :has-error-in-phone-input="hasErrorInPhoneInput"
    />
    <FormKit
      v-if="!hasActiveCampaign"
      name="message"
      type="textarea"
      label-class="text-sm font-medium text-n-slate-12"
      :input-class="context => inputClass(context)"
      :label="$t('PRE_CHAT_FORM.FIELDS.MESSAGE.LABEL')"
      :placeholder="$t('PRE_CHAT_FORM.FIELDS.MESSAGE.PLACEHOLDER')"
      validation="required"
      :validation-messages="{
        required: $t('PRE_CHAT_FORM.FIELDS.MESSAGE.ERROR'),
      }"
    />

    <CustomButton
      class="mt-3 mb-5 font-medium flex items-center justify-center gap-2"
      block
      :bg-color="widgetColor"
      :text-color="textColor"
      :disabled="isCreatingConversation"
    >
      <Spinner v-if="isCreatingConversation" class="p-0" />
      {{ $t('START_CONVERSATION') }}
    </CustomButton>
  </FormKit>
</template>

<style lang="scss">
.formkit-outer {
  @apply mt-2;

  .formkit-inner {
    input[type='checkbox'] {
      @apply size-4 outline-none;
    }
  }

  &[data-invalid] {
    .formkit-label {
      @apply text-n-ruby-10;
    }
    .formkit-inner input,
    .formkit-inner textarea,
    .formkit-inner select {
      @apply outline-n-ruby-8 dark:outline-n-ruby-8 hover:outline-n-ruby-9 dark:hover:outline-n-ruby-9 focus:outline-n-ruby-9 dark:focus:outline-n-ruby-9;
    }
  }
}

[data-invalid] .formkit-message {
  @apply text-n-ruby-10 block text-xs font-normal my-0.5 w-full;
}

.formkit-outer[data-type='checkbox'] .formkit-wrapper {
  @apply flex items-center gap-2 px-0.5;
}

.formkit-messages {
  @apply list-none m-0 p-0;
}
</style>
