<script>
import { useAlert } from 'dashboard/composables';
import {
  DuplicateContactException,
  ExceptionWithMessage,
} from 'shared/helpers/CustomErrors';
import { required, email } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';
import countries from 'shared/constants/countries.js';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Avatar from 'next/avatar/Avatar.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

export default {
  components: {
    NextButton,
    Avatar,
    ComboBox,
  },
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
  emits: ['cancel', 'success'],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      countries: countries,
      description: '',
      email: '',
      name: '',
      website: '',
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
        telegram: '',
      },
      socialProfileKeys: [
        { key: 'instagram', prefixURL: 'https://instagram.com/' },
        { key: 'facebook', prefixURL: 'https://facebook.com/' },
        { key: 'twitter', prefixURL: 'https://twitter.com/' },
        { key: 'linkedin', prefixURL: 'https://linkedin.com/' },
        { key: 'github', prefixURL: 'https://github.com/' },
        { key: 'telegram', prefixURL: 'https://t.me/' },
        { key: 'tiktok', prefixURL: 'https://tiktok.com/@' },
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
    website: {},
  },
  computed: {},
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
    countryNameWithCode({ name, id }) {
      if (!id) return name;
      if (!name && !id) return '';
      return `${name} (${id})`;
    },
    onCountryChange(value) {
      const selected = this.countries.find(c => c.id === value);
      this.country = selected
        ? { id: selected.id, name: selected.name }
        : { id: '', name: '' };
    },
    setContactObject() {
      const { email: emailAddress, name } = this.contact;
      const additionalAttributes = this.contact.additional_attributes || {};

      this.name = name || '';
      this.email = emailAddress || '';
      this.website = additionalAttributes.website || '';
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
        social_telegram_user_name: telegramUserName,
      } = additionalAttributes;
      this.socialProfileUserNames = {
        twitter: socialProfiles.twitter || twitterScreenName || '',
        facebook: socialProfiles.facebook || '',
        linkedin: socialProfiles.linkedin || '',
        github: socialProfiles.github || '',
        telegram: socialProfiles.telegram || telegramUserName || '',
        instagram: socialProfiles.instagram || '',
        tiktok: socialProfiles.tiktok || '',
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
        additional_attributes: {
          ...this.contact.additional_attributes,
          description: this.description,
          website: this.website,
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
    async handleSubmit() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }
      try {
        await this.onSubmit(this.getContactObject());
        this.onSuccess();
        useAlert(this.$t('CONTACT_FORM.SUCCESS_MESSAGE'));
      } catch (error) {
        if (error instanceof DuplicateContactException) {
          if (error.data.includes('email')) {
            useAlert(this.$t('CONTACT_FORM.FORM.EMAIL_ADDRESS.DUPLICATE'));
          }
        } else if (error instanceof ExceptionWithMessage) {
          useAlert(error.data);
        } else {
          useAlert(this.$t('CONTACT_FORM.ERROR_MESSAGE'));
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
          useAlert(this.$t('CONTACT_FORM.DELETE_AVATAR.API.SUCCESS_MESSAGE'));
        }
        this.avatarFile = null;
        this.avatarUrl = '';
      } catch (error) {
        useAlert(
          error.message
            ? error.message
            : this.$t('CONTACT_FORM.DELETE_AVATAR.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>

<template>
  <form
    class="w-full px-8 pt-6 pb-8 contact--form"
    @submit.prevent="handleSubmit"
  >
    <div class="flex flex-col mb-4 items-start gap-1 w-full">
      <label class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ $t('CONTACT_FORM.FORM.AVATAR.LABEL') }}
      </label>
      <Avatar
        :src="avatarUrl"
        :size="72"
        :name="contact.name"
        allow-upload
        rounded-full
        @upload="handleImageUpload"
        @delete="handleAvatarDelete"
      />
    </div>
    <div>
      <div class="w-full">
        <label :class="{ error: v$.name.$error }">
          {{ $t('CONTACT_FORM.FORM.NAME.LABEL') }}
          <input
            v-model="name"
            type="text"
            :placeholder="$t('CONTACT_FORM.FORM.NAME.PLACEHOLDER')"
            @input="v$.name.$touch"
          />
        </label>

        <label :class="{ error: v$.email.$error }">
          {{ $t('CONTACT_FORM.FORM.EMAIL_ADDRESS.LABEL') }}
          <input
            v-model="email"
            type="text"
            :placeholder="$t('CONTACT_FORM.FORM.EMAIL_ADDRESS.PLACEHOLDER')"
            @input="v$.email.$touch"
          />
          <span v-if="v$.email.$error" class="message">
            {{ $t('CONTACT_FORM.FORM.EMAIL_ADDRESS.ERROR') }}
          </span>
        </label>
      </div>
    </div>
    <div class="w-full">
      <label :class="{ error: v$.description.$error }">
        {{ $t('CONTACT_FORM.FORM.BIO.LABEL') }}
        <textarea
          v-model="description"
          type="text"
          :placeholder="$t('CONTACT_FORM.FORM.BIO.PLACEHOLDER')"
          @input="v$.description.$touch"
        />
      </label>
    </div>
    <woot-input
      v-model="website"
      class="w-full"
      :label="$t('CONTACT_PANEL.WEBSITE')"
      placeholder="https://example.com"
    />
    <div class="w-full mb-4">
      <label>
        {{ $t('CONTACT_FORM.FORM.COUNTRY.LABEL') }}
      </label>
      <ComboBox
        :model-value="country.id"
        :options="
          countries.map(c => ({
            value: c.id,
            label: countryNameWithCode(c),
          }))
        "
        class="[&>div>button]:!bg-n-alpha-black2"
        :placeholder="$t('CONTACT_FORM.FORM.COUNTRY.PLACEHOLDER')"
        :search-placeholder="$t('CONTACT_FORM.FORM.COUNTRY.SELECT_PLACEHOLDER')"
        @update:model-value="onCountryChange"
      />
    </div>
    <woot-input
      v-model="city"
      class="w-full"
      :label="$t('CONTACT_FORM.FORM.CITY.LABEL')"
      :placeholder="$t('CONTACT_FORM.FORM.CITY.PLACEHOLDER')"
    />

    <div class="w-full">
      <label>{{ $t('CONTACTS_PAGE.LIST.TABLE_HEADER.SOCIAL_PROFILES') }}</label>
      <div
        v-for="socialProfile in socialProfileKeys"
        :key="socialProfile.key"
        class="flex items-stretch w-full mb-4"
      >
        <span
          class="flex items-center h-10 px-2 text-sm border-solid border-y ltr:border-l rtl:border-r ltr:rounded-l-md rtl:rounded-r-md bg-n-solid-3 text-n-slate-11 border-n-weak"
        >
          {{ socialProfile.prefixURL }}
        </span>
        <input
          v-model="socialProfileUserNames[socialProfile.key]"
          class="input-group-field ltr:!rounded-l-none rtl:!rounded-r-none !mb-0"
          type="text"
        />
      </div>
    </div>
    <div class="flex flex-row justify-start w-full gap-2 px-0 py-2">
      <NextButton
        type="submit"
        :label="$t('CONTACT_FORM.FORM.SUBMIT')"
        :is-loading="inProgress"
      />
      <NextButton
        faded
        slate
        type="reset"
        :label="$t('CONTACT_FORM.FORM.CANCEL')"
        @click.prevent="onCancel"
      />
    </div>
  </form>
</template>
