<template>
  <div class="contact--profile">
    <div class="contact--info">
      <thumbnail
        v-if="showAvatar"
        :src="contact.thumbnail"
        size="56px"
        :username="contact.name"
        :status="contact.availability_status"
      />

      <div class="contact--details">
        <div v-if="showAvatar" class="contact--name-wrap">
          <h3 class="sub-block-title contact--name">
            {{ contact.name }}
          </h3>
          <a
            :href="contactProfileLink"
            class="fs-default"
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
        <p v-if="additionalAttributes.description" class="contact--bio">
          {{ additionalAttributes.description }}
        </p>
        <social-icons :social-profiles="socialProfiles" />
        <div class="contact--metadata">
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
        </div>
      </div>
      <div class="contact-actions">
        <woot-button
          v-tooltip="$t('CONTACT_PANEL.NEW_MESSAGE')"
          title="$t('CONTACT_PANEL.NEW_MESSAGE')"
          class="new-message"
          icon="chat"
          size="small"
          @click="toggleConversationModal"
        />
        <woot-button
          v-tooltip="$t('EDIT_CONTACT.BUTTON_LABEL')"
          title="$t('EDIT_CONTACT.BUTTON_LABEL')"
          class="edit-contact"
          icon="edit"
          variant="smooth"
          size="small"
          @click="toggleEditModal"
        />
        <woot-button
          v-if="isAdmin"
          v-tooltip="$t('CONTACT_PANEL.MERGE_CONTACT')"
          title="$t('CONTACT_PANEL.MERGE_CONTACT')"
          class="merge-contact"
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
          class="delete-contact"
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
      :message="confirmDeleteMessage"
      :confirm-text="$t('DELETE_CONTACT.CONFIRM.YES')"
      :reject-text="$t('DELETE_CONTACT.CONFIRM.NO')"
    />
  </div>
</template>
<script>
import { mixin as clickaway } from 'vue-clickaway';

import ContactInfoRow from './ContactInfoRow';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import SocialIcons from './SocialIcons';

import EditContact from './EditContact';
import NewConversation from './NewConversation';
import ContactMergeModal from 'dashboard/modules/contact/ContactMergeModal';
import alertMixin from 'shared/mixins/alertMixin';
import adminMixin from '../../../../mixins/isAdmin';
import { mapGetters } from 'vuex';
import flag from 'country-code-emoji';

export default {
  components: {
    ContactInfoRow,
    EditContact,
    Thumbnail,
    SocialIcons,
    NewConversation,
    ContactMergeModal,
  },
  mixins: [alertMixin, adminMixin, clickaway],
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
      return `${this.$t('DELETE_CONTACT.CONFIRM.MESSAGE')} ${
        this.contact.name
      } ?`;
    },
  },
  methods: {
    toggleMergeModal() {
      this.showMergeModal = !this.showMergeModal;
    },
    toggleEditModal() {
      this.showEditModal = !this.showEditModal;
    },
    toggleConversationModal() {
      this.showConversationModal = !this.showConversationModal;
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
        const countryFlag = countryCode ? flag(countryCode) : '🌎';
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
        if (this.$route.name !== 'contacts_dashboard') {
          this.$router.push({ name: 'contacts_dashboard' });
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

<style scoped lang="scss">
.contact--profile {
  position: relative;
  align-items: flex-start;
  padding: var(--space-normal);

  .user-thumbnail-box {
    margin-right: var(--space-normal);
  }
}

.contact--details {
  margin-top: var(--space-small);
  width: 100%;
}

.contact--info {
  text-align: left;
}

.contact--name-wrap {
  display: flex;
  align-items: center;
  margin-bottom: var(--space-small);
}

.contact--name {
  text-transform: capitalize;
  white-space: normal;
  margin: 0 var(--space-smaller) 0 0;

  a {
    color: var(--color-body);
  }
}

.contact--metadata {
  margin-bottom: var(--space-slab);
}

.contact-actions {
  margin-top: var(--space-small);
}

.contact-actions {
  display: flex;
  align-items: center;
  width: 100%;

  .new-message,
  .edit-contact,
  .merge-contact,
  .delete-contact {
    margin-right: var(--space-small);
  }
}
.merege-summary--card {
  padding: var(--space-normal);
}
.contact--bio {
  word-wrap: break-word;
}

.button--contact-menu {
  position: absolute;
  right: var(--space-normal);
  top: 0;
}
</style>
