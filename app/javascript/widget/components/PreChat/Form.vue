<template>
  <FormulateForm
    v-model="formValues"
    class="flex flex-1 flex-col p-6 overflow-y-auto"
    @submit="onSubmit"
  >
    <div v-for="(item, index) in enabledPreChatFields" :key="index">
      <FormulateInput
        v-if="isContactFieldVisible('emailAddress', item)"
        name="emailAddress"
        type="email"
        :label="$t('PRE_CHAT_FORM.FIELDS.EMAIL_ADDRESS.LABEL')"
        :placeholder="$t('PRE_CHAT_FORM.FIELDS.EMAIL_ADDRESS.PLACEHOLDER')"
        validation="bail|required|email"
        :validation-messages="{
          email: $t('PRE_CHAT_FORM.FIELDS.EMAIL_ADDRESS.VALID_ERROR'),
          required: $t('PRE_CHAT_FORM.FIELDS.EMAIL_ADDRESS.REQUIRED_ERROR'),
        }"
      />
      <FormulateInput
        v-if="isContactFieldVisible('fullName', item)"
        name="fullName"
        type="text"
        :label="$t('PRE_CHAT_FORM.FIELDS.FULL_NAME.LABEL')"
        :placeholder="$t('PRE_CHAT_FORM.FIELDS.FULL_NAME.PLACEHOLDER')"
        validation="required"
        :validation-messages="{
          required: $t('PRE_CHAT_FORM.FIELDS.FULL_NAME.REQUIRED_ERROR'),
        }"
      />
      <FormulateInput
        v-if="isContactFieldVisible('phoneNumber', item)"
        name="phoneNumber"
        type="text"
        :label="$t('PRE_CHAT_FORM.FIELDS.PHONE_NUMBER.LABEL')"
        :placeholder="$t('PRE_CHAT_FORM.FIELDS.PHONE_NUMBER.PLACEHOLDER')"
        validation="bail|required|isPhoneE164OrEmpty"
        :validation-messages="{
          isPhoneE164OrEmpty: $t(
            'PRE_CHAT_FORM.FIELDS.PHONE_NUMBER.VALID_ERROR'
          ),
          required: $t('PRE_CHAT_FORM.FIELDS.PHONE_NUMBER.REQUIRED_ERROR'),
        }"
      />
    </div>
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
