<template>
  <div class="relative items-center p-4 bg-white dark:bg-slate-900 w-full">
    <div class="text-left rtl:text-right flex flex-col gap-2 w-full">
      <div class="flex justify-between flex-row">
        <thumbnail
          v-if="showAvatar"
          :src="contact.thumbnail"
          size="56px"
          :username="contact.name"
          :status="contact.availability_status"
        />
        <woot-button
          v-if="showCloseButton"
          :icon="closeIconName"
          class="clear secondary rtl:rotate-180"
          @click="onPanelToggle"
        />
      </div>

      <div class="flex flex-col items-start gap-1.5 min-w-0 w-full">
        <div v-if="showAvatar" class="flex items-start gap-2 min-w-0 w-full">
          <h3
            class="flex-shrink min-w-0 text-base text-slate-800 dark:text-slate-100 capitalize my-0 max-w-full break-words"
          >
            {{ contact.name }}
          </h3>
          <div class="flex flex-row items-center gap-1">
            <fluent-icon
              v-if="contact.created_at"
              v-tooltip.left="
                `${$t('CONTACT_PANEL.CREATED_AT_LABEL')} ${dynamicTime(
                  contact.created_at
                )}`
              "
              icon="info"
              size="14"
              class="mt-0.5"
            />
            <a
              :href="contactProfileLink"
              class="text-base"
              target="_blank"
              rel="noopener nofollow noreferrer"
            >
              <woot-button
                size="tiny"
                icon="open"
                variant="clear"
                color-scheme="secondary"
              />
            </a>
          </div>
        </div>

        <p v-if="additionalAttributes.description" class="break-words mb-0.5">
          {{ additionalAttributes.description }}
        </p>
        <div class="flex flex-col gap-2 items-start w-full">
          <contact-info-row
            :href="contact.email ? `mailto:${contact.email}` : ''"
            :value="contact.email"
            icon="mail"
            emoji="✉️"
            :title="$t('CONTACT_PANEL.EMAIL_ADDRESS')"
            show-copy
          />
          <contact-info-row
            :href="contact.phone_number ? `tel:${contact.phone_number}` : ''"
            :value="contact.phone_number"
            icon="call"
            emoji="📞"
            :title="$t('CONTACT_PANEL.PHONE_NUMBER')"
            show-copy
          />
          <contact-info-row
            v-if="contact.identifier"
            :value="contact.identifier"
            icon="contact-identify"
            emoji="🪪"
            :title="$t('CONTACT_PANEL.IDENTIFIER')"
          />
          <contact-info-row
            :value="additionalAttributes.company_name"
            icon="building-bank"
            emoji="🏢"
            :title="$t('CONTACT_PANEL.COMPANY')"
          />
          <contact-info-row
            v-if="location || additionalAttributes.location"
            :value="location || additionalAttributes.location"
            icon="map"
            emoji="🌍"
            :title="$t('CONTACT_PANEL.LOCATION')"
          />
          <social-icons :social-profiles="socialProfiles" />
        </div>
      </div>
      <div class="flex items-center w-full mt-0.5 gap-2">
        <woot-button
          v-tooltip="$t('CONTACT_PANEL.NEW_MESSAGE')"
          title="$t('CONTACT_PANEL.NEW_MESSAGE')"
          icon="chat"
          size="small"
          @click="toggleConversationModal"
        />
        <woot-button
          v-tooltip="$t('EDIT_CONTACT.BUTTON_LABEL')"
          title="$t('EDIT_CONTACT.BUTTON_LABEL')"
          icon="edit"
          variant="smooth"
          size="small"
          @click="toggleEditModal"
        />
        <woot-button
          v-tooltip="$t('CONTACT_PANEL.MERGE_CONTACT')"
          title="$t('CONTACT_PANEL.MERGE_CONTACT')"
          icon="merge"
          variant="smooth"
          size="small"
          color-scheme="secondary"
          :disabled="uiFlags.isMerging"
          @click="openMergeModal"
        />
        <woot-button
          v-if="isAdmin"
          v-tooltip="$t('DELETE_CONTACT.BUTTON_LABEL')"
          title="$t('DELETE_CONTACT.BUTTON_LABEL')"
          icon="delete"
          variant="smooth"
          size="small"
          color-scheme="alert"
          :disabled="uiFlags.isDeleting"
          @click="toggleDeleteModal"
        />
      </div>
      <edit-contact
        v-if="showEditModal"
        :show="showEditModal"
        :contact="contact"
        @cancel="toggleEditModal"
      />
      <new-conversation
        v-if="contact.id"
        :show="showConversationModal"
        :contact="contact"
        @cancel="toggleConversationModal"
      />
      <contact-merge-modal
        v-if="showMergeModal"
        :primary-contact="contact"
        :show="showMergeModal"
        @close="toggleMergeModal"
      />
    </div>
    <woot-delete-modal
      v-if="showDeleteModal"
      :show.sync="showDeleteModal"
      :on-close="closeDelete"
      :on-confirm="confirmDeletion"
      :title="$t('DELETE_CONTACT.CONFIRM.TITLE')"
      :message="$t('DELETE_CONTACT.CONFIRM.MESSAGE')"
      :message-value="confirmDeleteMessage"
      :confirm-text="$t('DELETE_CONTACT.CONFIRM.YES')"
      :reject-text="$t('DELETE_CONTACT.CONFIRM.NO')"
    />
  </div>
</template>
<script>
import { mixin as clickaway } from 'vue-clickaway';
import timeMixin from 'dashboard/mixins/time';
import ContactInfoRow from './ContactInfoRow.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import SocialIcons from './SocialIcons.vue';

import EditContact from './EditContact.vue';
import NewConversation from './NewConversation.vue';
import ContactMergeModal from 'dashboard/modules/contact/ContactMergeModal.vue';
import alertMixin from 'shared/mixins/alertMixin';
import adminMixin from '../../../../mixins/isAdmin';
import { mapGetters } from 'vuex';
import { getCountryFlag } from 'dashboard/helper/flag';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import {
  isAConversationRoute,
  isAInboxViewRoute,
  getConversationDashboardRoute,
} from '../../../../helper/routeHelpers';

export default {
  components: {
    ContactInfoRow,
    EditContact,
    Thumbnail,
    SocialIcons,
    NewConversation,
    ContactMergeModal,
  },
  mixins: [alertMixin, adminMixin, clickaway, timeMixin],
  props: {
    contact: {
      type: Object,
      default: () => ({}),
    },
    channelType: {
      type: String,
      default: '',
    },
    showAvatar: {
      type: Boolean,
      default: true,
    },
    showCloseButton: {
      type: Boolean,
      default: true,
    },
    closeIconName: {
      type: String,
      default: 'chevron-right',
    },
  },
  data() {
    return {
      showEditModal: false,
      showConversationModal: false,
      showMergeModal: false,
      showDeleteModal: false,
    };
  },
  computed: {
    ...mapGetters({ uiFlags: 'contacts/getUIFlags' }),
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
      } = this.additionalAttributes;

      return { twitter: twitterScreenName, ...(socialProfiles || {}) };
    },
    // Delete Modal
    confirmDeleteMessage() {
      return ` ${this.contact.name}?`;
    },
  },
  methods: {
    toggleMergeModal() {
      this.showMergeModal = !this.showMergeModal;
    },
    toggleEditModal() {
      this.showEditModal = !this.showEditModal;
    },
    onPanelToggle() {
      this.$emit('toggle-panel');
    },
    toggleConversationModal() {
      this.showConversationModal = !this.showConversationModal;
      bus.$emit(BUS_EVENTS.NEW_CONVERSATION_MODAL, this.showConversationModal);
    },
    toggleDeleteModal() {
      this.showDeleteModal = !this.showDeleteModal;
    },
    confirmDeletion() {
      this.deleteContact(this.contact);
      this.closeDelete();
    },
    closeDelete() {
      this.showDeleteModal = false;
      this.showConversationModal = false;
      this.showEditModal = false;
    },
    findCountryFlag(countryCode, cityAndCountry) {
      try {
        const countryFlag = countryCode ? getCountryFlag(countryCode) : '🌎';
        return `${cityAndCountry} ${countryFlag}`;
      } catch (error) {
        return '';
      }
    },
    async deleteContact({ id }) {
      try {
        await this.$store.dispatch('contacts/delete', id);
        this.$emit('panel-close');
        this.showAlert(this.$t('DELETE_CONTACT.API.SUCCESS_MESSAGE'));

        if (isAConversationRoute(this.$route.name)) {
          this.$router.push({
            name: getConversationDashboardRoute(this.$route.name),
          });
        } else if (isAInboxViewRoute(this.$route.name)) {
          this.$router.push({
            name: 'inbox_view',
          });
        } else if (this.$route.name !== 'contacts_dashboard') {
          this.$router.push({
            name: 'contacts_dashboard',
          });
        }
      } catch (error) {
        this.showAlert(
          error.message
            ? error.message
            : this.$t('DELETE_CONTACT.API.ERROR_MESSAGE')
        );
      }
    },
    openMergeModal() {
      this.toggleMergeModal();
    },
  },
};
</script>
