<script>
import { mapGetters } from 'vuex';
import axios from 'axios';
import { useAlert } from 'dashboard/composables';
import {
  DuplicateContactException,
  ExceptionWithMessage,
} from 'shared/helpers/CustomErrors';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { useAdmin } from 'dashboard/composables/useAdmin';
import ContactInfoRow from './ContactInfoRow.vue';
import Avatar from 'next/avatar/Avatar.vue';
import SocialIcons from './SocialIcons.vue';
import EditContact from './EditContact.vue';
import ContactMergeModal from 'dashboard/modules/contact/ContactMergeModal.vue';
import ContactDeleteModal from 'dashboard/modules/contact/ContactDeleteModal.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import VoiceCallButton from 'dashboard/components-next/Contacts/VoiceCallButton.vue';
import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';

const SMS_API_BASE = 'https://smsgateway.garage.mn/api';
const API_TOKEN = 'YOUR_GARAGE_MN_API_TOKEN';

export default {
  components: {
    NextButton,
    ContactInfoRow,
    EditContact,
    Avatar,
    ComposeConversation,
    SocialIcons,
    ContactMergeModal,
    ContactDeleteModal,
    VoiceCallButton,
    InlineInput,
  },
  props: {
    contact: {
      type: Object,
      default: () => ({}),
    },
    showAvatar: {
      type: Boolean,
      default: true,
    },
  },
  emits: ['panelClose'],
  setup() {
    const { isAdmin } = useAdmin();
    return {
      isAdmin,
    };
  },
  data() {
    return {
      showEditModal: false,
      isEditingName: false,
      editName: '',
      showSmsModal: false,
      smsMessage: '',
      isSendingSms: false,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'contacts/getUIFlags',
      currentChat: 'getSelectedChat',
    }),
    contactProfileLink() {
      return `/app/accounts/${this.$route.params.accountId}/contacts/${this.contact.id}`;
    },
    additionalAttributes() {
      return this.contact.additional_attributes || {};
    },
    location() {
      const {
        country = '',
        city = '',
        country_code: countryCode,
      } = this.additionalAttributes;
      const cityAndCountry = [city, country].filter(item => !!item).join(', ');

      if (!cityAndCountry) {
        return '';
      }
      return this.findCountryFlag(countryCode, cityAndCountry);
    },
    socialProfiles() {
      const {
        social_profiles: socialProfiles,
        screen_name: twitterScreenName,
        social_telegram_user_name: telegramUsername,
      } = this.additionalAttributes;

      const telegram = socialProfiles?.telegram || telegramUsername || '';
      const twitter = socialProfiles?.twitter || twitterScreenName || '';

      return {
        ...(socialProfiles || {}),
        twitter,
        telegram,
      };
    },
    phoneOperator() {
      if (!this.contact.phone_number) {
        return null;
      }
      return this.getOperatorFromPhone(this.contact.phone_number);
    },
  },
  watch: {
    'contact.id': {
      handler(id) {
        if (id) {
          this.$store.dispatch('contacts/fetchContactableInbox', id);
        }
      },
      immediate: true,
    },
  },
  methods: {
    dynamicTime,
    toggleEditModal() {
      this.showEditModal = !this.showEditModal;
    },
    findCountryFlag(countryCode, cityAndCountry) {
      try {
        if (!countryCode) {
          return `${cityAndCountry} 🌎`;
        }

        const code = countryCode?.toLowerCase();
        return `${cityAndCountry} <span class="fi fi-${code} size-3.5"></span>`;
      } catch (error) {
        return '';
      }
    },
    startEditingName() {
      this.editName = this.contact.name || '';
      this.isEditingName = true;
      this.$nextTick(() => {
        this.$refs.nameInput?.focus();
      });
    },
    saveNameEdit() {
      if (!this.isEditingName) return;
      this.isEditingName = false;
      const trimmed = this.editName.trim();
      if (trimmed && trimmed !== this.contact.name) {
        this.updateContactField({ name: trimmed });
      }
    },
    cancelNameEdit() {
      this.isEditingName = false;
    },
    onFieldUpdate(field, value) {
      this.updateContactField({ [field]: value });
    },
    async updateContactField(attrs) {
      const contactId = this.contact.id;
      try {
        await this.$store.dispatch('contacts/update', {
          id: contactId,
          ...attrs,
        });
        useAlert(this.$t('CONTACT_FORM.SUCCESS_MESSAGE'));
        await this.$store.dispatch('contacts/fetchContactableInbox', contactId);
      } catch (error) {
        if (error instanceof DuplicateContactException) {
          const detail = error.contactErrorDetail;
          if (detail) {
            useAlert(detail);
          } else {
            const invalidAttrs = Array.isArray(error.data) ? error.data : [];
            if (invalidAttrs.includes('email')) {
              useAlert(this.$t('CONTACT_FORM.FORM.EMAIL_ADDRESS.DUPLICATE'));
            } else if (invalidAttrs.includes('phone_number')) {
              useAlert(this.$t('CONTACT_FORM.FORM.PHONE_NUMBER.DUPLICATE'));
            } else {
              useAlert(this.$t('CONTACT_FORM.ERROR_MESSAGE'));
            }
          }
        } else if (error instanceof ExceptionWithMessage) {
          useAlert(error.data);
        } else {
          useAlert(error.message || this.$t('CONTACT_FORM.ERROR_MESSAGE'));
        }
      }
    },
    openSmsModal() {
      this.showSmsModal = true;
    },
    closeSmsModal() {
      this.showSmsModal = false;
      this.smsMessage = '';
    },
    async handleSendSms() {
      if (!this.smsMessage.trim()) {
        useAlert(
          this.$t('CONTACT_PANEL.SEND_SMS_MODAL.EMPTY_MESSAGE_ERROR'),
          'error'
        );
        return;
      }
      this.isSendingSms = true;
      try {
        const response = await axios.post(`${SMS_API_BASE}/send`, {
          phone: this.contact.phone_number,
          message: this.smsMessage,
          token: API_TOKEN,
        });
        if (response.data.status !== 'success') {
          throw new Error(response.data.message || 'SMS sending failed');
        }
        useAlert(
          this.$t('CONTACT_PANEL.SEND_SMS_MODAL.SUCCESS_MESSAGE'),
          'success'
        );
        this.closeSmsModal();
      } catch (error) {
        const errorMessage = error.response?.data?.message || error.message;
        useAlert(errorMessage, 'error');
      } finally {
        this.isSendingSms = false;
      }
    },
    getOperatorFromPhone(phone) {
      const cleanPhone = phone.replace(/\D/g, '');

      if (cleanPhone.startsWith('976')) {
        const prefix = cleanPhone.substring(3, 5);
        switch (prefix) {
          case '99':
          case '95':
          case '94':
          case '93':
          case '92':
          case '91':
          case '90':
            return 'Mobicom';
          case '88':
          case '89':
          case '85':
          case '84':
          case '83':
          case '82':
          case '80':
            return 'Unitel';
          case '77':
          case '75':
          case '74':
          case '73':
          case '72':
          case '71':
          case '70':
            return 'Skytel';
          case '68':
          case '67':
          case '66':
          case '65':
          case '64':
          case '63':
          case '60':
            return 'G-Mobile';
          default:
            return 'Unknown';
        }
      }
      return 'Unknown';
    },
  },
};
</script>

<template>
  <div class="relative items-center w-full p-4">
    <div class="flex flex-col w-full gap-2 text-left rtl:text-right">
      <div class="flex flex-row justify-between">
        <Avatar
          v-if="showAvatar"
          :src="contact.thumbnail"
          :name="contact.name"
          :status="contact.availability_status"
          :size="48"
          hide-offline-status
          rounded-full
        />
      </div>

      <div class="flex flex-col items-start gap-1.5 min-w-0 w-full">
        <div v-if="showAvatar" class="flex items-center w-full min-w-0 gap-3">
          <InlineInput
            v-if="isEditingName"
            ref="nameInput"
            v-model="editName"
            custom-input-class="!text-base !font-medium"
            class="!w-fit"
            @enter-press="saveNameEdit"
            @escape-press="cancelNameEdit"
            @blur="saveNameEdit"
          />
          <h3
            v-else
            class="group/name flex-shrink max-w-full min-w-0 my-0 text-base capitalize break-words text-n-slate-12 cursor-pointer hover:text-n-slate-12/80"
            :title="$t('CONTACT_PANEL.CLICK_TO_EDIT')"
            @click="startEditingName"
          >
            {{ contact.name }}
            <span
              class="i-lucide-pencil text-xs text-n-slate-10 opacity-0 group-hover/name:opacity-100 transition-opacity ml-1 align-middle"
            />
          </h3>
          <div class="flex flex-row items-center gap-2">
            <span
              v-if="contact.created_at"
              v-tooltip.left="
                `${$t('CONTACT_PANEL.CREATED_AT_LABEL')} ${dynamicTime(
                  contact.created_at
                )}`
              "
              class="i-lucide-info text-sm text-n-slate-10"
            />
            <a
              :href="contactProfileLink"
              target="_blank"
              rel="noopener nofollow noreferrer"
              class="leading-3"
            >
              <span class="i-lucide-external-link text-sm text-n-slate-10" />
            </a>
          </div>
        </div>

        <p v-if="additionalAttributes.description" class="break-words mb-0.5">
          {{ additionalAttributes.description }}
        </p>
        <div class="flex flex-col items-start w-full gap-2">
          <ContactInfoRow
            :href="contact.email ? `mailto:${contact.email}` : ''"
            :value="contact.email"
            icon="mail"
            emoji="✉️"
            :title="$t('CONTACT_PANEL.EMAIL_ADDRESS')"
            show-copy
            editable
            @update="value => onFieldUpdate('email', value)"
          />
          <ContactInfoRow
            :href="contact.phone_number ? `tel:${contact.phone_number}` : ''"
            :value="contact.phone_number"
            icon="call"
            emoji="📞"
            :title="$t('CONTACT_PANEL.PHONE_NUMBER')"
            show-copy
            editable
            @update="value => onFieldUpdate('phone_number', value)"
          />
          <ContactInfoRow
            v-if="phoneOperator && phoneOperator !== 'Unknown'"
            :value="phoneOperator"
            icon="signal-high"
            emoji="📶"
            :title="$t('CONTACT_PANEL.OPERATOR')"
          />
          <ContactInfoRow
            v-if="contact.plate_number"
            :value="contact.plate_number"
            icon="map"
            emoji="🚗"
            :title="$t('CONTACT_PANEL.PLATE_NUMBER')"
            show-copy
          />
          <ContactInfoRow
            v-if="contact.identifier"
            :value="contact.identifier"
            icon="contact-identify"
            emoji="🪪"
            :title="$t('CONTACT_PANEL.IDENTIFIER')"
          />
          <ContactInfoRow
            :value="additionalAttributes.company_name"
            icon="building-bank"
            emoji="🏢"
            :title="$t('CONTACT_PANEL.COMPANY')"
            editable
            @update="
              value =>
                updateContactField({
                  additional_attributes: {
                    ...additionalAttributes,
                    company_name: value,
                  },
                })
            "
          />
          <ContactInfoRow
            v-if="location || additionalAttributes.location"
            :value="location || additionalAttributes.location"
            icon="map"
            emoji="🌍"
            :title="$t('CONTACT_PANEL.LOCATION')"
          />
          <SocialIcons :social-profiles="socialProfiles" />
        </div>
      </div>
      <div class="flex items-center w-full mt-0.5 gap-2">
        <ComposeConversation :contact-id="String(contact.id)">
          <template #trigger>
            <NextButton
              v-tooltip.top-end="$t('CONTACT_PANEL.NEW_MESSAGE')"
              icon="i-ph-chat-circle-dots"
              slate
              faded
              sm
            />
          </template>
        </ComposeConversation>
        <VoiceCallButton
          :phone="contact.phone_number"
          :contact-id="contact.id"
          :conversation-id="currentChat?.id"
          icon="i-lucide-phone"
          sm
          faded
          slate
          :tooltip-label="$t('CONTACT_PANEL.CALL')"
        />
        <NextButton
          v-if="contact.phone_number"
          v-tooltip.top-end="$t('CONTACT_PANEL.SEND_SMS')"
          icon="i-ph-device-mobile"
          slate
          faded
          sm
          @click="openSmsModal"
        />
        <NextButton
          v-tooltip.top-end="$t('EDIT_CONTACT.BUTTON_LABEL')"
          icon="i-ph-pencil-simple"
          slate
          faded
          sm
          @click="toggleEditModal"
        />
        <ContactMergeModal :primary-contact="contact">
          <template #trigger>
            <NextButton
              v-tooltip.top-end="$t('CONTACT_PANEL.MERGE_CONTACT')"
              icon="i-ph-arrows-merge"
              slate
              faded
              sm
              :disabled="uiFlags.isMerging"
            />
          </template>
        </ContactMergeModal>
        <ContactDeleteModal
          v-if="isAdmin"
          :contact="contact"
          @deleted="$emit('panelClose')"
        >
          <template #trigger>
            <NextButton
              v-tooltip.top-end="$t('DELETE_CONTACT.BUTTON_LABEL')"
              icon="i-ph-trash"
              slate
              faded
              sm
              ruby
              :disabled="uiFlags.isDeleting"
            />
          </template>
        </ContactDeleteModal>
      </div>
      <EditContact
        :show="showEditModal"
        :contact="contact"
        @cancel="toggleEditModal"
      />
    </div>
    <div
      v-if="showSmsModal"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
      @click.self="closeSmsModal"
    >
      <div
        class="relative flex flex-col w-full max-w-lg mx-4 bg-white dark:bg-n-slate-800 rounded-lg shadow-xl"
      >
        <div
          class="flex items-center justify-between p-4 border-b border-solid border-n-slate-50 dark:border-n-slate-700"
        >
          <h3 class="text-lg font-medium text-n-slate-12">
            {{ $t('CONTACT_PANEL.SEND_SMS_MODAL.TITLE') }}
          </h3>
          <NextButton
            icon="i-ph-x"
            variant="clear"
            color="secondary"
            @click="closeSmsModal"
          />
        </div>
        <div class="p-4">
          <textarea
            v-model="smsMessage"
            rows="5"
            class="w-full p-2 text-sm leading-6 transition-colors duration-200 ease-in-out bg-white border border-solid rounded-md resize-none border-n-slate-50 dark:bg-n-slate-900 text-n-slate-12 dark:border-n-slate-600 focus:border-w-primary-500"
            :placeholder="$t('CONTACT_PANEL.SEND_SMS_MODAL.PLACEHOLDER')"
          />
        </div>
        <div
          class="flex justify-end p-4 gap-2 bg-n-slate-25 dark:bg-n-slate-900 border-t border-solid border-n-slate-50 dark:border-n-slate-700 rounded-b-lg"
        >
          <NextButton color="secondary" variant="clear" @click="closeSmsModal">
            {{ $t('CONTACT_PANEL.SEND_SMS_MODAL.CANCEL') }}
          </NextButton>
          <NextButton
            :disabled="!smsMessage.trim() || isSendingSms"
            :loading="isSendingSms"
            @click="handleSendSms"
          >
            {{ $t('CONTACT_PANEL.SEND_SMS_MODAL.SEND') }}
          </NextButton>
        </div>
      </div>
    </div>
  </div>
</template>
