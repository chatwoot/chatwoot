<script>
import { mapGetters } from 'vuex';
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
import ContactAssigneeSelector from 'dashboard/components-next/Contacts/ContactAssigneeSelector.vue';
import ContactChatBotToggle from 'dashboard/components-next/Contacts/ContactChatBotToggle.vue';
import FeaturedAttributeBadges from 'dashboard/components-next/FeaturedAttributes/FeaturedAttributeBadges.vue';
import { useFeaturedAttributes } from 'dashboard/composables/useFeaturedAttributes';
import { computed, toRef } from 'vue';
import { useStore } from 'vuex';

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
    ContactAssigneeSelector,
    ContactChatBotToggle,
    FeaturedAttributeBadges,
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
  setup(props) {
    const { isAdmin } = useAdmin();
    const store = useStore();
    const contactRef = toRef(props, 'contact');
    const currentChat = computed(() => store.getters.getSelectedChat);
    const { featuredBadges: featuredContactBadges } = useFeaturedAttributes(
      'contact_attribute',
      contactRef
    );
    const { featuredBadges: featuredConversationBadges } =
      useFeaturedAttributes('conversation_attribute', currentChat);
    return {
      isAdmin,
      featuredContactBadges,
      featuredConversationBadges,
    };
  },
  data() {
    return {
      showEditModal: false,
      isEditingName: false,
      editName: '',
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
      return (
        this.contact.additionalAttributes ||
        this.contact.additional_attributes ||
        {}
      );
    },
    phoneNumber() {
      const phone = this.contact.phoneNumber || this.contact.phone_number || '';
      if (phone) return phone;

      const sender = this.currentChat?.meta?.sender || {};
      return (
        sender.phone_number ||
        sender.phoneNumber ||
        this.contact.identifier ||
        ''
      );
    },
    documentNumber() {
      return this.contact.documentNumber || this.contact.document_number || '';
    },
    location() {
      const {
        country = '',
        city = '',
        country_code: countryCodeSnake,
        countryCode,
      } = this.additionalAttributes;
      const resolvedCountryCode = countryCodeSnake || countryCode;
      const cityAndCountry = [city, country].filter(item => !!item).join(', ');

      if (!cityAndCountry) {
        return '';
      }
      return this.findCountryFlag(resolvedCountryCode, cityAndCountry);
    },
    socialProfiles() {
      const {
        social_profiles: socialProfilesSnake,
        socialProfiles: socialProfilesCamel,
        screen_name: twitterScreenNameSnake,
        screenName: twitterScreenNameCamel,
        social_telegram_user_name: telegramUsernameSnake,
        socialTelegramUserName: telegramUsernameCamel,
      } = this.additionalAttributes;
      const socialProfiles = socialProfilesCamel || socialProfilesSnake || {};
      const twitterScreenName =
        twitterScreenNameCamel || twitterScreenNameSnake;

      const telegram =
        socialProfiles.telegram ||
        telegramUsernameCamel ||
        telegramUsernameSnake ||
        '';
      const twitter = socialProfiles?.twitter || twitterScreenName || '';

      return {
        ...(socialProfiles || {}),
        twitter,
        telegram,
      };
    },
  },
  watch: {
    'contact.id': {
      handler(id) {
        this.$store.dispatch('contacts/fetchContactableInbox', id);
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
          return `${cityAndCountry} ðŸŒŽ`;
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
  },
};
</script>

<template>
  <div class="relative items-center w-full px-2 py-2">
    <div class="flex flex-col w-full gap-1 text-left rtl:text-right">
      <div class="flex flex-row items-start gap-2.5 w-full min-w-0">
        <Avatar
          v-if="showAvatar"
          :src="contact.thumbnail"
          :name="contact.name"
          :status="contact.availability_status"
          :size="48"
          hide-offline-status
          class="flex-shrink-0"
        />
        <div class="flex flex-col gap-0.5 min-w-0 flex-1 justify-center">
          <div class="flex items-start gap-2 min-w-0">
            <InlineInput
              v-if="isEditingName"
              ref="nameInput"
              v-model="editName"
              custom-input-class="!text-base !font-medium !w-auto max-w-full [field-sizing:content]"
              class="!w-fit min-w-0"
              @enter-press="saveNameEdit"
              @escape-press="cancelNameEdit"
              @blur="saveNameEdit"
            />
            <h3
              v-else-if="showAvatar"
              class="group/name flex-1 min-w-0 my-0 text-base font-medium break-words text-n-slate-12 cursor-pointer hover:text-n-slate-12/80"
              :title="$t('CONTACT_PANEL.CLICK_TO_EDIT')"
              @click="startEditingName"
            >
              {{ contact.name }}
              <span
                class="i-lucide-pencil text-xs text-n-slate-10 opacity-0 group-hover/name:opacity-100 transition-opacity ml-1 align-middle"
              />
            </h3>
            <div class="flex flex-row items-center gap-2 flex-shrink-0 pt-0.5">
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
                :aria-label="$t('CONTACT_PANEL.VIEW_PROFILE')"
              >
                <span class="i-lucide-external-link text-sm text-n-slate-10" />
              </a>
            </div>
          </div>
          <ContactInfoRow
            :href="phoneNumber ? `tel:${phoneNumber}` : ''"
            :value="phoneNumber"
            icon="call"
            emoji="📞"
            :title="$t('CONTACT_PANEL.PHONE_NUMBER')"
            show-copy
            editable
            @update="value => onFieldUpdate('phone_number', value)"
          />
        </div>
      </div>

      <p v-if="additionalAttributes.description" class="break-words mb-0.5">
        {{ additionalAttributes.description }}
      </p>
      <div class="flex flex-col items-start w-full gap-1.5">
        <ContactInfoRow
          :value="documentNumber"
          icon="contact-identify"
          icon-class="i-ph-identification-card"
          emoji="🪪"
          :title="$t('CONTACT_PANEL.DOCUMENT_NUMBER')"
          show-copy
          editable
          @update="value => onFieldUpdate('document_number', value)"
        />
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
        <div
          v-if="
            featuredContactBadges.length || featuredConversationBadges.length
          "
          class="flex flex-col gap-1 mt-1"
        >
          <FeaturedAttributeBadges
            v-if="featuredContactBadges.length"
            :badges="featuredContactBadges"
            variant="contact"
          />
          <FeaturedAttributeBadges
            v-if="featuredConversationBadges.length"
            :badges="featuredConversationBadges"
            variant="conversation"
          />
        </div>
        <ContactAssigneeSelector
          v-if="contact.id"
          :contact="contact"
          class="mt-1"
        />
        <ContactChatBotToggle
          v-if="contact.id"
          :contact="contact"
          class="mt-1"
        />
      </div>
      <div class="flex items-center w-full mt-1 gap-1.5">
        <ComposeConversation :contact-id="String(contact.id)">
          <template #trigger>
            <NextButton
              v-tooltip.top-end="$t('CONTACT_PANEL.NEW_MESSAGE')"
              :aria-label="$t('CONTACT_PANEL.NEW_MESSAGE')"
              icon="i-ph-chat-circle-dots"
              slate
              faded
              xs
            />
          </template>
        </ComposeConversation>
        <VoiceCallButton
          :phone="phoneNumber"
          :contact-id="contact.id"
          :conversation-id="currentChat?.id"
          icon="i-lucide-phone"
          size="xs"
          faded
          slate
          :tooltip-label="$t('CONTACT_PANEL.CALL')"
        />
        <NextButton
          v-tooltip.top-end="$t('EDIT_CONTACT.BUTTON_LABEL')"
          :aria-label="$t('EDIT_CONTACT.BUTTON_LABEL')"
          icon="i-ph-pencil-simple"
          slate
          faded
          xs
          @click="toggleEditModal"
        />
        <ContactMergeModal :primary-contact="contact">
          <template #trigger>
            <NextButton
              v-tooltip.top-end="$t('CONTACT_PANEL.MERGE_CONTACT')"
              :aria-label="$t('CONTACT_PANEL.MERGE_CONTACT')"
              icon="i-ph-arrows-merge"
              slate
              faded
              xs
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
              :aria-label="$t('DELETE_CONTACT.BUTTON_LABEL')"
              icon="i-ph-trash"
              slate
              faded
              xs
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
  </div>
</template>
