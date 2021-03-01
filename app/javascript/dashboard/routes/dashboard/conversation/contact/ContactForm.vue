<template>
  <form class="contact--form" @submit.prevent="handleSubmit">
    <div class="row">
      <div class="columns">
        <label :class="{ error: $v.name.$error }">
          {{ $t('CONTACT_FORM.FORM.NAME.LABEL') }}
          <input
            v-model.trim="name"
            type="text"
            :placeholder="$t('CONTACT_FORM.FORM.NAME.PLACEHOLDER')"
            @input="$v.name.$touch"
          />
        </label>

        <label :class="{ error: $v.email.$error }">
          {{ $t('CONTACT_FORM.FORM.EMAIL_ADDRESS.LABEL') }}
          <input
            v-model.trim="email"
            type="text"
            :placeholder="$t('CONTACT_FORM.FORM.EMAIL_ADDRESS.PLACEHOLDER')"
            @input="$v.email.$touch"
          />
        </label>
      </div>
    </div>
    <div class="medium-12 columns">
      <label :class="{ error: $v.description.$error }">
        {{ $t('CONTACT_FORM.FORM.BIO.LABEL') }}
        <textarea
          v-model.trim="description"
          type="text"
          :placeholder="$t('CONTACT_FORM.FORM.BIO.PLACEHOLDER')"
          @input="$v.description.$touch"
        />
      </label>
    </div>
    <div class="row">
      <woot-input
        v-model.trim="phoneNumber"
        class="columns"
        :label="$t('CONTACT_FORM.FORM.PHONE_NUMBER.LABEL')"
        :placeholder="$t('CONTACT_FORM.FORM.PHONE_NUMBER.PLACEHOLDER')"
      />
    </div>
    <woot-input
      v-model.trim="companyName"
      class="columns"
      :label="$t('CONTACT_FORM.FORM.COMPANY_NAME.LABEL')"
      :placeholder="$t('CONTACT_FORM.FORM.COMPANY_NAME.PLACEHOLDER')"
    />
    <div class="medium-12 columns">
      <label>
        Social Profiles
      </label>
      <div
        v-for="socialProfile in socialProfileKeys"
        :key="socialProfile.key"
        class="input-group"
      >
        <span class="input-group-label">{{ socialProfile.prefixURL }}</span>
        <input
          v-model="socialProfileUserNames[socialProfile.key]"
          class="input-group-field"
          type="text"
        />
      </div>
    </div>
    <div class="modal-footer">
      <div class="medium-12 columns">
        <woot-submit-button
          :loading="inProgress"
          :button-text="$t('CONTACT_FORM.FORM.SUBMIT')"
        />
        <button class="button clear" @click.prevent="onCancel">
          {{ $t('CONTACT_FORM.FORM.CANCEL') }}
        </button>
      </div>
    </div>
  </form>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import {
  DuplicateContactException,
  ExceptionWithMessage,
} from 'shared/helpers/CustomErrors';
import { required } from 'vuelidate/lib/validators';

export default {
  mixins: [alertMixin],
  props: {
    contact: {
      type: Object,
      default: () => ({}),
    },
    inProgress: {
      type: Boolean,
      default: false,
    },
    onSubmit: {
      type: Function,
      default: () => {},
    },
  },
  data() {
    return {
      hasADuplicateContact: false,
      duplicateContact: {},
      companyName: '',
      description: '',
      email: '',
      name: '',
      phoneNumber: '',
      socialProfileUserNames: {
        facebook: '',
        twitter: '',
        linkedin: '',
      },
      socialProfileKeys: [
        { key: 'facebook', prefixURL: 'https://facebook.com/' },
        { key: 'twitter', prefixURL: 'https://twitter.com/' },
        { key: 'linkedin', prefixURL: 'https://linkedin.com/' },
      ],
    };
  },
  validations: {
    name: {
      required,
    },
    description: {},
    email: {},
    companyName: {},
    phoneNumber: {},
    bio: {},
  },

  watch: {
    contact() {
      this.setContactObject();
    },
  },
  mounted() {
    this.setContactObject();
  },
  methods: {
    onCancel() {
      this.$emit('cancel');
    },
    onSuccess() {
      this.$emit('success');
    },
    setContactObject() {
      const { email: email, phone_number: phoneNumber, name } = this.contact;
      const additionalAttributes = this.contact.additional_attributes || {};

      this.name = name || '';
      this.email = email || '';
      this.phoneNumber = phoneNumber || '';
      this.companyName = additionalAttributes.company_name || '';
      this.description = additionalAttributes.description || '';
      const {
        social_profiles: socialProfiles = {},
        screen_name: twitterScreenName,
      } = additionalAttributes;
      this.socialProfileUserNames = {
        twitter: socialProfiles.twitter || twitterScreenName || '',
        facebook: socialProfiles.facebook || '',
        linkedin: socialProfiles.linkedin || '',
      };
    },
    getContactObject() {
      return {
        id: this.contact.id,
        name: this.name,
        email: this.email,
        phone_number: this.phoneNumber,
        additional_attributes: {
          ...this.contact.additional_attributes,
          description: this.description,
          company_name: this.companyName,
          social_profiles: this.socialProfileUserNames,
        },
      };
    },
    resetDuplicate() {
      this.hasADuplicateContact = false;
      this.duplicateContact = {};
    },
    async handleSubmit() {
      this.resetDuplicate();
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      try {
        await this.onSubmit(this.getContactObject());
        this.onSuccess();
        this.showAlert(this.$t('CONTACT_FORM.SUCCESS_MESSAGE'));
      } catch (error) {
        if (error instanceof DuplicateContactException) {
          this.hasADuplicateContact = true;
          this.duplicateContact = error.data;
          this.showAlert(this.$t('CONTACT_FORM.CONTACT_ALREADY_EXIST'));
        } else if (error instanceof ExceptionWithMessage) {
          this.showAlert(error.data);
        } else {
          this.showAlert(this.$t('CONTACT_FORM.ERROR_MESSAGE'));
        }
      }
    },
  },
};
</script>

<style scoped lang="scss">
.contact--form {
  padding: var(--space-normal) var(--space-large) var(--space-large);

  .columns {
    padding: 0 var(--space-smaller);
  }
}

.input-group-label {
  font-size: var(--font-size-small);
}
</style>
