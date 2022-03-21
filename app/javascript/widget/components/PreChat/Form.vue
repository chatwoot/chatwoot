<template>
  <FormulateForm
    v-model="formValues"
    class="flex flex-1 flex-col p-6 overflow-y-auto"
    @submit="onSubmit"
  >
    <FormulateInput
      v-for="item in enabledPreChatFields"
      :key="item.name"
      :name="item.name"
      :type="item.type"
      :label="getLabel(item)"
      :placeholder="getPlaceHolder(item.name)"
      :validation="getValidation(item)"
      :validation-messages="{
        isPhoneE164OrEmpty: $t('PRE_CHAT_FORM.FIELDS.PHONE_NUMBER.VALID_ERROR'),
        email: $t('PRE_CHAT_FORM.FIELDS.EMAIL_ADDRESS.VALID_ERROR'),
        required: getRequiredErrorMessage(item.name),
      }"
    />
    <FormulateInput
      v-if="!hasActiveCampaign"
      name="message"
      type="textarea"
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
export default {
  components: {
    CustomButton,
    Spinner,
  },
  mixins: [routerMixin],
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
      return this.options.preChatFields || [];
    },
    enabledPreChatFields() {
      console.log('preChatFields', this.preChatFields);
      return this.preChatFields.filter(field => field.enabled);
    },
  },
  methods: {
    isContactFieldVisible(field, item) {
      const itemExists = this.preChatFields.find(
        option => option.name === field
      );
      return (
        itemExists &&
        item.name === field &&
        this.preChatFields.find(option => option.name === field).enabled &&
        !this.disableContactFields
      );
    },
    isContactFieldRequired(field) {
      const itemExists = this.preChatFields.find(
        option => option.name === field
      );
      return (
        itemExists &&
        this.preChatFields.find(option => option.name === field).required &&
        !this.disableContactFields
      );
    },
    isValidationEnabled(field) {
      return (
        this.isContactFieldRequired(field) &&
        this.isContactFieldVisible(field, { name: field })
      );
    },
    getLabel(item) {
      if (this.labels[item.item])
        return this.$t(`PRE_CHAT_FORM.FIELDS.${this.labels[item.item]}.LABEL`);
      return item.label;
    },
    getPlaceHolder(fieldName) {
      if (this.labels[fieldName])
        return this.$t(
          `PRE_CHAT_FORM.FIELDS.${this.labels[fieldName]}.PLACEHOLDER`
        );
      return fieldName;
    },
    getRequiredErrorMessage(fieldName) {
      if (this.labels[fieldName])
        return this.$t(
          `PRE_CHAT_FORM.FIELDS.${this.labels[fieldName]}.REQUIRED_ERROR`
        );
      return `${fieldName} is required`;
    },
    getValidation(item) {
      if (!this.isValidationEnabled(item.name)) {
        return '';
      }
      switch (item.name) {
        case 'emailAddress':
          return 'bail|required|email';
        case 'phoneNumber':
          return 'bail|required|isPhoneE164OrEmpty';
        default:
          return 'required';
      }
    },
    onSubmit() {
      const { emailAddress, fullName, phoneNumber, message } = this.formValues;
      this.$emit('submit', {
        fullName,
        phoneNumber,
        emailAddress,
        message,
        activeCampaignId: this.activeCampaign.id,
      });
    },
  },
};
</script>
