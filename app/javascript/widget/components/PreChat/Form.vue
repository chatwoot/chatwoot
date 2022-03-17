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
    <form-input
      v-if="areContactFieldsVisible"
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
      v-if="areContactFieldsVisible"
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
      default: () => ({}),
    },
    disableContactFields: {
      type: Boolean,
      default: false,
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
    // For campaign, message field is not required
    if (this.hasActiveCampaign) {
      return identityValidations;
    }
    if (this.areContactFieldsVisible) {
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
    areContactFieldsVisible() {
      return this.options.requireEmail && !this.disableContactFields;
    },
  },
  methods: {
    onSubmit() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      this.$emit('submit', {
        fullName: this.fullName,
        emailAddress: this.emailAddress,
        message: this.message,
        activeCampaignId: this.activeCampaign.id,
      });
    },
  },
};
</script>
