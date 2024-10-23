<template>
  <form
    class="w-full px-8 pt-6 pb-8 contact--form"
    @submit.prevent="handleSubmit"
  >
    <div>
      <div class="w-full">
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
    <div>
      <div class="w-full">
        <div class="w-full">
          <label :class="{ error: $v.name.$error }">
            {{ $t('CONTACT_FORM.FORM.NAME.LABEL') }}
            <input v-model.trim="name" type="text" @input="$v.name.$touch" />
          </label>
        </div>
        <div class="w-full">
          <label
            :class="{
              error: isPhoneNumberNotValid(phoneNumber, activeDialCode),
            }"
          >
            {{ $t('CONTACT_FORM.FORM.PHONE_NUMBER.LABEL') }}
            <woot-phone-input
              v-model="phoneNumber"
              :value="phoneNumber"
              :error="isPhoneNumberNotValid(phoneNumber, activeDialCode)"
              :placeholder="
                $t('CONTACT_FORM.FORM.PHONE_NUMBER.CONTACT_PLACEHOLDER')
              "
              @input="onPhoneNumberInputChange"
              @blur="$v.phoneNumber.$touch"
              @setCode="setPhoneCode"
            />
            <span
              v-if="isPhoneNumberNotValid(phoneNumber, activeDialCode)"
              class="message"
            >
              {{ phoneNumberError(phoneNumber, activeDialCode) }}
            </span>
          </label>
        </div>
        <div class="w-full">
          <label
            :class="{
              error: isPhoneNumberNotValid(phoneNumber2, activeDialCode2),
            }"
          >
            {{ $t('CONTACT_FORM.FORM.SECONDARY_PHONE_NUMBER.LABEL') }}
            <woot-phone-input
              v-model="phoneNumber2"
              :value="phoneNumber2"
              :error="isPhoneNumberNotValid(phoneNumber2, activeDialCode2)"
              :placeholder="
                $t(
                  'CONTACT_FORM.FORM.SECONDARY_PHONE_NUMBER.CONTACT_PLACEHOLDER'
                )
              "
              @input="onPhoneNumber2InputChange"
              @blur="$v.phoneNumber2.$touch"
              @setCode="setPhoneCode2"
            />
            <span
              v-if="isPhoneNumberNotValid(phoneNumber2, activeDialCode2)"
              class="message"
            >
              {{ phoneNumberError(phoneNumber2, activeDialCode2) }}
            </span>
          </label>
        </div>
        <label :class="{ error: $v.email.$error }">
          {{ $t('CONTACT_FORM.FORM.EMAIL_ADDRESS.LABEL') }}
          <input v-model.trim="email" type="text" @input="$v.email.$touch" />
          <span v-if="$v.email.$error" class="message">
            {{ $t('CONTACT_FORM.FORM.EMAIL_ADDRESS.ERROR') }}
          </span>
        </label>
      </div>
    </div>
    <div class="gap-2 flex flex-row">
      <div class="w-[50%]">
        <label>
          {{ $t('CONTACT_PANEL.NEW_ACTION.ASSIGNEE') }}
        </label>
        <div class="multiselect-wrap--small">
          <multiselect
            v-model="agent"
            class="no-margin"
            placeholder=""
            label="name"
            track-by="id"
            :options="agents"
            :max-height="160"
            :close-on-select="true"
            :show-labels="false"
          />
        </div>
      </div>
      <div class="w-[50%]">
        <label>
          {{ $t('CONTACT_PANEL.NEW_ACTION.TEAM') }}
        </label>
        <div class="multiselect-wrap--small">
          <multiselect
            v-model="team"
            class="no-margin"
            placeholder=""
            label="name"
            track-by="id"
            :options="teams"
            :max-height="160"
            :close-on-select="true"
            :show-labels="false"
          />
        </div>
      </div>
    </div>
    <div class="conversation--actions">
      <accordion-item
        :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONTACT_ATTRIBUTES')"
        :is-open="isContactSidebarItemOpen('is_ct_custom_attr_open')"
        compact
        @click="value => toggleSidebarUIState('is_ct_custom_attr_open', value)"
      >
        <custom-attributes
          :contact-id="contact.id"
          attribute-type="contact_attribute"
          attribute-class="conversation--attribute"
          attribute-from="contact_form"
          :custom-attributes="customAttributes"
          class="even"
          @customAttributeChanged="customAttributeChanged"
        />
      </accordion-item>
    </div>

    <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
      <div class="w-full">
        <woot-submit-button
          :loading="inProgress"
          :button-text="$t('CONTACT_FORM.FORM.SUBMIT')"
          @click="submitEnabled = true"
        />
        <button class="button clear" @click.prevent="onCancel">
          {{ $t('CONTACT_FORM.FORM.CANCEL') }}
        </button>
      </div>
    </div>
  </form>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import {
  DuplicateContactException,
  ExceptionWithMessage,
} from 'shared/helpers/CustomErrors';
import { required, email } from 'vuelidate/lib/validators';
import countries from 'shared/constants/countries.js';
import { isPhoneNumberValid } from 'shared/helpers/Validators';
import parsePhoneNumber from 'libphonenumber-js';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import AccordionItem from 'dashboard/components/Accordion/AccordionItem.vue';
import CustomAttributes from 'dashboard/routes/dashboard/conversation/customAttributes/CustomAttributes.vue';

export default {
  components: {
    CustomAttributes,
    AccordionItem,
  },
  mixins: [alertMixin, uiSettingsMixin],
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
      submitEnabled: false,
      countries: countries,
      agent: null,
      team: null,
      email: '',
      name: '',
      phoneNumber: '',
      phoneNumber2: '',
      activeDialCode: '',
      activeDialCode2: '',
      avatarFile: null,
      avatarUrl: '',
      country: {
        id: '',
        name: '',
      },
      customAttributes: {},
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
    phoneNumber: {},
    phoneNumber2: {},
  },
  computed: {
    ...mapGetters({
      agents: 'agents/getAgents',
      teams: 'teams/getTeams',
      currentUser: 'getCurrentUser',
    }),
    parsePhoneNumber() {
      return parsePhoneNumber(this.phoneNumber);
    },
    parsePhoneNumber2() {
      return parsePhoneNumber(this.phoneNumber2);
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
    setPhoneNumber2() {
      if (this.parsePhoneNumber2 && this.parsePhoneNumber2.countryCallingCode) {
        return this.phoneNumber2;
      }
      if (this.phoneNumber2 === '' && this.activeDialCode2 !== '') {
        return '';
      }
      return this.activeDialCode2
        ? `${this.activeDialCode2}${this.phoneNumber2}`
        : '';
    },
  },
  mounted() {
    this.$store.dispatch('agents/get');
    if (this.contact?.id) {
      this.$store
        .dispatch('contacts/show', { id: this.contact.id })
        .then(() => {
          this.setContactObject();
          this.setDialCode();
          this.setDialCode2();
        });
    } else {
      this.agent = this.currentUser;
      this.$store.dispatch('teams/getMyTeam').then(response => {
        if (response.data) this.team = response.data;
      });
    }
  },
  methods: {
    isPhoneNumberNotValid(phoneNumber, activeDialCode) {
      if (phoneNumber !== '') {
        return (
          !isPhoneNumberValid(phoneNumber, activeDialCode) ||
          (phoneNumber !== '' ? activeDialCode === '' : false)
        );
      }
      return false;
    },
    phoneNumberError(phoneNumber, activeDialCode) {
      if (activeDialCode === '') {
        return this.$t('CONTACT_FORM.FORM.PHONE_NUMBER.DIAL_CODE_ERROR');
      }
      if (!isPhoneNumberValid(phoneNumber, activeDialCode)) {
        return this.$t('CONTACT_FORM.FORM.PHONE_NUMBER.CONTACT_ERROR');
      }
      return '';
    },
    onCancel() {
      this.$emit('cancel');
    },
    onSuccess() {
      this.$emit('success');
    },
    customAttributeChanged(key, value) {
      this.customAttributes = {
        ...this.customAttributes,
        [key]: value,
      };
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
    setDialCode2() {
      if (
        this.phoneNumber2 !== '' &&
        this.parsePhoneNumber2 &&
        this.parsePhoneNumber2.countryCallingCode
      ) {
        const dialCode = this.parsePhoneNumber2.countryCallingCode;
        this.activeDialCode2 = `+${dialCode}`;
      }
    },
    setContactObject() {
      const {
        email: emailAddress,
        phone_number: phoneNumber,
        secondary_phone_number: phoneNumber2,
        name,
      } = this.contact;

      this.name = name || '';
      this.email = emailAddress || '';
      this.phoneNumber = phoneNumber || '';
      this.phoneNumber2 = phoneNumber2 || '';
      this.avatarUrl = this.contact.thumbnail || '';
      this.customAttributes = this.contact.custom_attributes || {};
      this.agent = this.contact.assignee || {};
      this.team = this.contact.team || {};
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
        secondary_phone_number: this.setPhoneNumber2,
        stage_id: this.contact.stage_id,
        custom_attributes: this.customAttributes,
        assignee_id: this.agent?.id,
        team_id: this.team?.id,
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
    onPhoneNumber2InputChange(value, code) {
      this.activeDialCode2 = code;
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
    setPhoneCode2(code) {
      if (this.phoneNumber2 !== '' && this.parsePhoneNumber2) {
        const dialCode = this.parsePhoneNumber2.countryCallingCode;
        if (dialCode === code) {
          return;
        }
        this.activeDialCode2 = `+${dialCode}`;
        const newPhoneNumber = this.phoneNumber2.replace(
          `+${dialCode}`,
          `${code}`
        );
        this.phoneNumber2 = newPhoneNumber;
      } else {
        this.activeDialCode2 = code;
      }
    },
    async handleSubmit() {
      if (!this.submitEnabled) return;
      this.$v.$touch();
      if (
        this.$v.$invalid ||
        this.isPhoneNumberNotValid(this.phoneNumber, this.activeDialCode) ||
        this.isPhoneNumberNotValid(this.phoneNumber2, this.activeDialCode2)
      ) {
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
          this.showAlert(error.message);
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
::v-deep {
  .multiselect .multiselect__tags .multiselect__single {
    @apply pl-0;
  }
}
</style>
