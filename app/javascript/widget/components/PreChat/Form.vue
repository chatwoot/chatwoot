<template>
  <form
    class="flex flex-1 flex-col p-6 overflow-y-auto"
    @submit.prevent="onSubmit"
  >
    <div
      v-if="shouldShowHeaderMessage"
      class="text-black-800 text-sm leading-5"
    >
      {{ headerMessage }}
    </div>
    <div v-for="(item, index) in preChatFields" :key="index">
      <form-input
        v-if="isContactFieldVisible('fullName', item)"
        v-model="fullName"
        class="mt-5"
        :label="$t('PRE_CHAT_FORM.FIELDS.FULL_NAME.LABEL')"
        :placeholder="$t('PRE_CHAT_FORM.FIELDS.FULL_NAME.PLACEHOLDER')"
        type="text"
        :error="
          $v.fullName && $v.fullName.$error
            ? $t('PRE_CHAT_FORM.FIELDS.FULL_NAME.REQUIRED_ERROR')
            : ''
        "
      />
      <form-input
        v-if="isContactFieldVisible('emailAddress', item)"
        v-model="emailAddress"
        class="mt-5"
        :label="$t('PRE_CHAT_FORM.FIELDS.EMAIL_ADDRESS.LABEL')"
        :placeholder="$t('PRE_CHAT_FORM.FIELDS.EMAIL_ADDRESS.PLACEHOLDER')"
        type="email"
        :error="$v.emailAddress && emailErrorMessage"
      />
      <form-input
        v-if="isContactFieldVisible('phoneNumber', item)"
        v-model="phoneNumber"
        class="mt-5"
        :label="$t('PRE_CHAT_FORM.FIELDS.PHONE_NUMBER.LABEL')"
        :placeholder="$t('PRE_CHAT_FORM.FIELDS.PHONE_NUMBER.PLACEHOLDER')"
        type="number"
        :error="$v.phoneNumber && phoneNumberErrorMessage"
      />
    </div>

    <form-text-area
      v-if="!hasActiveCampaign"
      v-model="message"
      class="my-5"
      :label="$t('PRE_CHAT_FORM.FIELDS.MESSAGE.LABEL')"
      :placeholder="$t('PRE_CHAT_FORM.FIELDS.MESSAGE.PLACEHOLDER')"
      :error="$v.message.$error ? $t('PRE_CHAT_FORM.FIELDS.MESSAGE.ERROR') : ''"
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
  </form>
</template>

<script>
import CustomButton from 'shared/components/Button';
import FormInput from '../Form/Input';
import FormTextArea from '../Form/TextArea';
import Spinner from 'shared/components/Spinner';
import { mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import { isPhoneE164OrEmpty } from 'shared/helpers/Validators';
import { required, minLength, email } from 'vuelidate/lib/validators';

import { isEmptyObject } from 'widget/helpers/utils';
import routerMixin from 'widget/mixins/routerMixin';
export default {
  components: {
    FormInput,
    FormTextArea,
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
  validations() {
    let identityValidations = {};
    if (this.isContactFieldRequired('emailAddress')) {
      identityValidations = {
        ...identityValidations,
        emailAddress: {
          required,
          email,
        },
      };
    }
    if (this.isContactFieldRequired('phoneNumber')) {
      identityValidations = {
        ...identityValidations,
        phoneNumber: {
          required,
          isPhoneE164OrEmpty,
        },
      };
    }
    if (this.isContactFieldRequired('fullName')) {
      identityValidations = {
        ...identityValidations,
        fullName: {
          required,
        },
      };
    }

    const messageValidation = {
      message: {
        required,
        minLength: minLength(1),
      },
    };
    // For campaign, message field is not required
    if (this.hasActiveCampaign) {
      return identityValidations;
    }
    return {
      ...identityValidations,
      ...messageValidation,
    };
  },
  data() {
    return {
      fullName: '',
      emailAddress: '',
      phoneNumber: '',
      message: '',
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
    emailErrorMessage() {
      let errorMessage = '';
      if (!this.$v.emailAddress.$error) {
        errorMessage = '';
      } else if (!this.$v.emailAddress.required) {
        errorMessage = this.$t(
          'PRE_CHAT_FORM.FIELDS.EMAIL_ADDRESS.REQUIRED_ERROR'
        );
      } else if (!this.$v.emailAddress.email) {
        errorMessage = this.$t(
          'PRE_CHAT_FORM.FIELDS.EMAIL_ADDRESS.VALID_ERROR'
        );
      }
      return errorMessage;
    },
    phoneNumberErrorMessage() {
      let errorMessage = '';
      if (!this.$v.phoneNumber.$error) {
        errorMessage = '';
      } else if (!this.$v.phoneNumber.required) {
        errorMessage = this.$t(
          'PRE_CHAT_FORM.FIELDS.PHONE_NUMBER.REQUIRED_ERROR'
        );
      } else if (!this.$v.phoneNumber.email) {
        errorMessage = this.$t('PRE_CHAT_FORM.FIELDS.PHONE_NUMBER.VALID_ERROR');
      }
      return errorMessage;
    },
  },
  methods: {
    isContactFieldVisible(field, item) {
      return (
        item.name === field &&
        this.preChatFields.find(option => option.name === field).enabled
      );
    },
    isContactFieldRequired(field) {
      return this.preChatFields.find(option => option.name === field).required;
    },
    onSubmit() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      this.$emit('submit', {
        fullName: this.fullName,
        phoneNumber: this.phoneNumber,
        emailAddress: this.emailAddress,
        message: this.message,
        activeCampaignId: this.activeCampaign.id,
      });
    },
  },
};
</script>
