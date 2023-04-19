<!-- eslint-disable vue/this-in-template -->
<template>
  <form class="contact--form" @submit.prevent="handleSubmit">
    <div class="row">
      <div class="columns">
        <woot-avatar-uploader
          :label="$t('CONTACT_FORM.FORM.AVATAR.LABEL')"
          :src="avatarUrl"
          :username-avatar="name"
          :delete-avatar="!!avatarUrl"
          class="settings-item"
          @change="handleImageUpload"
          @onAvatarDelete="handleAvatarDelete"
        />
      </div>
    </div>
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
          <span v-if="$v.email.$error" class="message">
            {{ $t('CONTACT_FORM.FORM.EMAIL_ADDRESS.ERROR') }}
          </span>
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
      <div class="medium-12 columns">
        <label
          :class="{
            error: isPhoneNumberNotValid,
          }"
        >
          {{ $t('CONTACT_FORM.FORM.PHONE_NUMBER.LABEL') }}
          <woot-phone-input
            v-model="phoneNumber"
            :value="phoneNumber"
            :error="isPhoneNumberNotValid"
            :placeholder="$t('CONTACT_FORM.FORM.PHONE_NUMBER.PLACEHOLDER')"
            @input="onPhoneNumberInputChange"
            @blur="$v.phoneNumber.$touch"
            @setCode="setPhoneCode"
          />
          <span v-if="isPhoneNumberNotValid" class="message">
            {{ phoneNumberError }}
          </span>
        </label>
        <div
          v-if="isPhoneNumberNotValid || !phoneNumber"
          class="callout small warning"
        >
          {{ $t('CONTACT_FORM.FORM.PHONE_NUMBER.HELP') }}
        </div>
      </div>
    </div>
    <woot-input
      v-model.trim="companyName"
      class="columns"
      :label="$t('CONTACT_FORM.FORM.COMPANY_NAME.LABEL')"
      :placeholder="$t('CONTACT_FORM.FORM.COMPANY_NAME.PLACEHOLDER')"
    />
    <div class="row">
      <div class="medium-12 columns">
        <label>
          {{ $t('CONTACT_FORM.FORM.COUNTRY.LABEL') }}
        </label>
        <multiselect
          v-model="country"
          track-by="id"
          label="name"
          :placeholder="$t('CONTACT_FORM.FORM.COUNTRY.PLACEHOLDER')"
          selected-label
          :select-label="$t('CONTACT_FORM.FORM.COUNTRY.SELECT_PLACEHOLDER')"
          :deselect-label="$t('CONTACT_FORM.FORM.COUNTRY.REMOVE')"
          :custom-label="countryNameWithCode"
          :max-height="160"
          :options="countries"
          :allow-empty="true"
          :option-height="104"
        />
      </div>
    </div>
    <woot-input
      v-model="city"
      class="columns"
      :label="$t('CONTACT_FORM.FORM.CITY.LABEL')"
      :placeholder="$t('CONTACT_FORM.FORM.CITY.PLACEHOLDER')"
    />

    <div class="medium-12 columns">
      <label> Social Profiles </label>
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
import { required, email } from 'vuelidate/lib/validators';
import countries from 'shared/constants/countries.js';
import { isPhoneNumberValid } from 'shared/helpers/Validators';
import parsePhoneNumber from 'libphonenumber-js';

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
      countries: countries,
      companyName: '',
      description: '',
      email: '',
      name: '',
      phoneNumber: '',
      activeDialCode: '',
      avatarFile: null,
      avatarUrl: '',
      country: {
        id: '',
        name: '',
      },
      city: '',
      socialProfileUserNames: {
        facebook: '',
        twitter: '',
        linkedin: '',
        github: '',
      },
      socialProfileKeys: [
        { key: 'facebook', prefixURL: 'https://facebook.com/' },
        { key: 'twitter', prefixURL: 'https://twitter.com/' },
        { key: 'linkedin', prefixURL: 'https://linkedin.com/' },
        { key: 'github', prefixURL: 'https://github.com/' },
      ],
    };
  },
  validations: {
    name: {
      required,
    },
    description: {},
    email: {
      email,
    },
    companyName: {},
    phoneNumber: {},
    bio: {},
  },
  computed: {
    parsePhoneNumber() {
      return parsePhoneNumber(this.phoneNumber);
    },
    isPhoneNumberNotValid() {
      if (this.phoneNumber !== '') {
        return (
          !isPhoneNumberValid(this.phoneNumber, this.activeDialCode) ||
          (this.phoneNumber !== '' ? this.activeDialCode === '' : false)
        );
      }
      return false;
    },
    phoneNumberError() {
      if (this.activeDialCode === '') {
        return this.$t('CONTACT_FORM.FORM.PHONE_NUMBER.DIAL_CODE_ERROR');
      }
      if (!isPhoneNumberValid(this.phoneNumber, this.activeDialCode)) {
        return this.$t('CONTACT_FORM.FORM.PHONE_NUMBER.ERROR');
      }
      return '';
    },
    setPhoneNumber() {
      if (this.parsePhoneNumber && this.parsePhoneNumber.countryCallingCode) {
        return this.phoneNumber;
      }
      if (this.phoneNumber === '' && this.activeDialCode !== '') {
        return '';
      }
      return this.activeDialCode
        ? `${this.activeDialCode}${this.phoneNumber}`
        : '';
    },
  },
  watch: {
    contact() {
      this.setContactObject();
    },
  },
  mounted() {
    this.setContactObject();
    this.setDialCode();
  },
  methods: {
    onCancel() {
      this.$emit('cancel');
    },
    onSuccess() {
      this.$emit('success');
    },
    countryNameWithCode({ name, id }) {
      if (!id) return name;
      if (!name && !id) return '';
      return `${name} (${id})`;
    },
    setDialCode() {
      if (
        this.phoneNumber !== '' &&
        this.parsePhoneNumber &&
        this.parsePhoneNumber.countryCallingCode
      ) {
        const dialCode = this.parsePhoneNumber.countryCallingCode;
        this.activeDialCode = `+${dialCode}`;
      }
    },
    setContactObject() {
      const {
        email: emailAddress,
        phone_number: phoneNumber,
        name,
      } = this.contact;
      const additionalAttributes = this.contact.additional_attributes || {};

      this.name = name || '';
      this.email = emailAddress || '';
      this.phoneNumber = phoneNumber || '';
      this.companyName = additionalAttributes.company_name || '';
      this.country = {
        id: additionalAttributes.country_code || '',
        name:
          additionalAttributes.country ||
          this.$t('CONTACT_FORM.FORM.COUNTRY.SELECT_COUNTRY'),
      };
      this.city = additionalAttributes.city || '';
      this.description = additionalAttributes.description || '';
      this.avatarUrl = this.contact.thumbnail || '';
      const {
        social_profiles: socialProfiles = {},
        screen_name: twitterScreenName,
      } = additionalAttributes;
      this.socialProfileUserNames = {
        twitter: socialProfiles.twitter || twitterScreenName || '',
        facebook: socialProfiles.facebook || '',
        linkedin: socialProfiles.linkedin || '',
        github: socialProfiles.github || '',
        instagram: socialProfiles.instagram || '',
      };
    },
    getContactObject() {
      if (this.country === null) {
        this.country = {
          id: '',
          name: '',
        };
      }
      const contactObject = {
        id: this.contact.id,
        name: this.name,
        email: this.email,
        phone_number: this.setPhoneNumber,
        additional_attributes: {
          ...this.contact.additional_attributes,
          description: this.description,
          company_name: this.companyName,
          country_code: this.country.id,
          country:
            this.country.name ===
            this.$t('CONTACT_FORM.FORM.COUNTRY.SELECT_COUNTRY')
              ? ''
              : this.country.name,
          city: this.city,
          social_profiles: this.socialProfileUserNames,
        },
      };
      if (this.avatarFile) {
        contactObject.avatar = this.avatarFile;
        contactObject.isFormData = true;
      }
      return contactObject;
    },
    onPhoneNumberInputChange(value, code) {
      this.activeDialCode = code;
    },
    setPhoneCode(code) {
      if (this.phoneNumber !== '' && this.parsePhoneNumber) {
        const dialCode = this.parsePhoneNumber.countryCallingCode;
        if (dialCode === code) {
          return;
        }
        this.activeDialCode = `+${dialCode}`;
        const newPhoneNumber = this.phoneNumber.replace(
          `+${dialCode}`,
          `${code}`
        );
        this.phoneNumber = newPhoneNumber;
      } else {
        this.activeDialCode = code;
      }
    },
    async handleSubmit() {
      this.$v.$touch();
      if (this.$v.$invalid || this.isPhoneNumberNotValid) {
        return;
      }
      try {
        await this.onSubmit(this.getContactObject());
        this.onSuccess();
        this.showAlert(this.$t('CONTACT_FORM.SUCCESS_MESSAGE'));
      } catch (error) {
        if (error instanceof DuplicateContactException) {
          if (error.data.includes('email')) {
            this.showAlert(
              this.$t('CONTACT_FORM.FORM.EMAIL_ADDRESS.DUPLICATE')
            );
          } else if (error.data.includes('phone_number')) {
            this.showAlert(this.$t('CONTACT_FORM.FORM.PHONE_NUMBER.DUPLICATE'));
          }
        } else if (error instanceof ExceptionWithMessage) {
          this.showAlert(error.data);
        } else {
          this.showAlert(this.$t('CONTACT_FORM.ERROR_MESSAGE'));
        }
      }
    },
    handleImageUpload({ file, url }) {
      this.avatarFile = file;
      this.avatarUrl = url;
    },
    async handleAvatarDelete() {
      try {
        if (this.contact && this.contact.id) {
          await this.$store.dispatch('contacts/deleteAvatar', this.contact.id);
          this.showAlert(
            this.$t('CONTACT_FORM.DELETE_AVATAR.API.SUCCESS_MESSAGE')
          );
        }
        this.avatarFile = null;
        this.avatarUrl = '';
        this.activeDialCode = '';
      } catch (error) {
        this.showAlert(
          error.message
            ? error.message
            : this.$t('CONTACT_FORM.DELETE_AVATAR.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>

<style scoped lang="scss">
input[readonly] {
  background-color: #e3e9f2;
  outline: none;
}
.contact--form {
  padding: var(--space-normal) var(--space-large) var(--space-large);

  .columns {
    padding: 0 var(--space-smaller);
  }
}

.input-group-label {
  font-size: var(--font-size-small);
}

::v-deep {
  .multiselect .multiselect__tags .multiselect__single {
    padding-left: 0;
  }
}
</style>
