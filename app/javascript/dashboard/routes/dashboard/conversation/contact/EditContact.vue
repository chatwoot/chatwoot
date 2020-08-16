<template>
  <woot-modal :show.sync="show" :on-close="onCancel">
    <div class="column content-box">
      <woot-modal-header
        :header-title="$t('EDIT_CONTACT.TITLE')"
        :header-content="$t('EDIT_CONTACT.DESC')"
      />
      <form @submit.prevent="onSubmit">
        <div class="row">
          <div class="medium-3">
            <woot-avatar-uploader
              :label="$t('EDIT_CONTACT.FORM.AVATAR.LABEL')"
              @change="handleImageUpload"
            />
          </div>
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
        <div class="medium-12">
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
export default {
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
      name: '',
      email: '',
      phoneNumber: '',
      location: '',
      companyName: '',
    };
  },
  validations: {
    name: {},
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
      const {
        additional_attributes: additionalAttributes,
        email: email,
        phone_number: phoneNumber,
        name,
      } = this.contact;
      this.name = name || '';
      this.email = email || '';
      this.phoneNumber = phoneNumber || '';
      this.location = additionalAttributes.location || '';
      this.companyName = additionalAttributes.company_name || '';
      this.description = additionalAttributes.description || '';
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
          social_profiles: this.socialProfiles,
        },
      };
    },
    onSubmit() {
      this.$store.dispatch('contacts/update', this.getContactObject());
    },
  },
};
</script>
