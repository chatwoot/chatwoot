<template>
  <woot-modal :show.sync="show" :on-close="onCancel">
    <div class="column content-box">
      <woot-modal-header
        :header-title="
          `${$t('EDIT_CONTACT.TITLE')} - ${contact.name || contact.email}`
        "
        :header-content="$t('EDIT_CONTACT.DESC')"
      />
      <form class="edit-contact--form" @submit.prevent="onSubmit">
        <div class="row">
          <div class="medium-9 columns">
            <label :class="{ error: $v.name.$error }">
              {{ $t('EDIT_CONTACT.FORM.NAME.LABEL') }}
              <input
                v-model.trim="name"
                type="text"
                :placeholder="$t('EDIT_CONTACT.FORM.NAME.PLACEHOLDER')"
                @input="$v.name.$touch"
              />
            </label>

            <label :class="{ error: $v.email.$error }">
              {{ $t('EDIT_CONTACT.FORM.EMAIL_ADDRESS.LABEL') }}
              <input
                v-model.trim="email"
                type="text"
                :placeholder="$t('EDIT_CONTACT.FORM.EMAIL_ADDRESS.PLACEHOLDER')"
                @input="$v.email.$touch"
              />
            </label>
          </div>
        </div>
        <div class="medium-12 columns">
          <label :class="{ error: $v.description.$error }">
            {{ $t('EDIT_CONTACT.FORM.BIO.LABEL') }}
            <textarea
              v-model.trim="description"
              type="text"
              :placeholder="$t('EDIT_CONTACT.FORM.BIO.PLACEHOLDER')"
              @input="$v.description.$touch"
            />
          </label>
        </div>
        <div class="row">
          <woot-input
            v-model.trim="phoneNumber"
            class="medium-6 columns"
            :label="$t('EDIT_CONTACT.FORM.PHONE_NUMBER.LABEL')"
            :placeholder="$t('EDIT_CONTACT.FORM.PHONE_NUMBER.PLACEHOLDER')"
          />

          <woot-input
            v-model.trim="location"
            class="medium-6 columns"
            :label="$t('EDIT_CONTACT.FORM.LOCATION.LABEL')"
            :placeholder="$t('EDIT_CONTACT.FORM.LOCATION.PLACEHOLDER')"
          />
        </div>
        <woot-input
          v-model.trim="companyName"
          class="medium-6 columns"
          :label="$t('EDIT_CONTACT.FORM.COMPANY_NAME.LABEL')"
          :placeholder="$t('EDIT_CONTACT.FORM.COMPANY_NAME.PLACEHOLDER')"
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
            <woot-submit-button :button-text="$t('EDIT_CONTACT.FORM.SUBMIT')" />
            <button class="button clear" @click.prevent="onCancel">
              {{ $t('EDIT_CONTACT.FORM.CANCEL') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </woot-modal>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import { DuplicateContactException } from 'shared/helpers/CustomErrors';
import { required } from 'vuelidate/lib/validators';

export default {
  mixins: [alertMixin],
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    contact: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      hasADuplicateContact: false,
      duplicateContact: {},
      companyName: '',
      description: '',
      email: '',
      location: '',
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
    location: {},
    bio: {},
  },
  watch: {
    contact() {
      this.setContactObject();
    },
  },
  methods: {
    onCancel() {
      this.$emit('cancel');
    },
    setContactObject() {
      const { email: email, phone_number: phoneNumber, name } = this.contact;
      const additionalAttributes = this.contact.additional_attributes || {};

      this.name = name || '';
      this.email = email || '';
      this.phoneNumber = phoneNumber || '';
      this.location = additionalAttributes.location || '';
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
          location: this.location,
          company_name: this.companyName,
          social_profiles: this.socialProfileUserNames,
        },
      };
    },
    resetDuplicate() {
      this.hasADuplicateContact = false;
      this.duplicateContact = {};
    },
    async onSubmit() {
      this.resetDuplicate();
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      try {
        await this.$store.dispatch('contacts/update', this.getContactObject());
        this.showAlert(this.$t('EDIT_CONTACT.SUCCESS_MESSAGE'));
      } catch (error) {
        if (error instanceof DuplicateContactException) {
          this.hasADuplicateContact = true;
          this.duplicateContact = error.data;
          this.showAlert(this.$t('EDIT_CONTACT.CONTACT_ALREADY_EXIST'));
        } else {
          this.showAlert(this.$t('EDIT_CONTACT.ERROR_MESSAGE'));
        }
      }
    },
  },
};
</script>

<style scoped lang="scss">
.edit-contact--form {
  padding: var(--space-normal) var(--space-large) var(--space-large);

  .columns {
    padding: 0 var(--space-smaller);
  }
}
</style>
