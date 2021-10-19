<template>
  <div class="contact--profile">
    <div class="contact--info">
      <thumbnail
        :src="contact.thumbnail"
        size="56px"
        :username="contact.name"
        :status="contact.availability_status"
      />

      <div class="contact--details">
        <h3 class="sub-block-title contact--name">
          {{ contact.name }}
        </h3>
        <p v-if="additionalAttributes.description" class="contact--bio">
          {{ additionalAttributes.description }}
        </p>
        <social-icons :social-profiles="socialProfiles" />
        <div class="contact--metadata">
          <contact-info-row
            :href="contact.email ? `mailto:${contact.email}` : ''"
            :value="contact.email"
            icon="ion-email"
            emoji="✉️"
            :title="$t('CONTACT_PANEL.EMAIL_ADDRESS')"
            show-copy
          />

          <contact-info-row
            :href="contact.phone_number ? `tel:${contact.phone_number}` : ''"
            :value="contact.phone_number"
            icon="ion-ios-telephone"
            emoji="📞"
            :title="$t('CONTACT_PANEL.PHONE_NUMBER')"
          />
          <contact-info-row
            v-if="additionalAttributes.location"
            :value="additionalAttributes.location"
            icon="ion-map"
            emoji="🌍"
            :title="$t('CONTACT_PANEL.LOCATION')"
          />
          <contact-info-row
            :value="additionalAttributes.company_name"
            icon="ion-briefcase"
            emoji="🏢"
            :title="$t('CONTACT_PANEL.COMPANY')"
          />
        </div>
      </div>
      <div class="contact-actions">
        <woot-button
          v-if="showNewMessage"
          v-tooltip="$t('CONTACT_PANEL.NEW_MESSAGE')"
          title="$t('CONTACT_PANEL.NEW_MESSAGE')"
          class="new-message"
          icon="ion-chatboxes"
          size="small expanded"
          @click="toggleConversationModal"
        />
        <woot-button
          v-tooltip="$t('EDIT_CONTACT.BUTTON_LABEL')"
          title="$t('EDIT_CONTACT.BUTTON_LABEL')"
          class="edit-contact"
          icon="ion-edit"
          variant="smooth"
          size="small expanded"
          @click="toggleEditModal"
        />
        <woot-button
          v-if="isAdmin"
          v-tooltip="$t('CONTACT_PANEL.MERGE_CONTACT')"
          title="$t('CONTACT_PANEL.MERGE_CONTACT')"
          class="merge-contact"
          icon="ion-merge"
          variant="smooth"
          size="small expanded"
          color-scheme="secondary"
          :disabled="uiFlags.isMerging"
          @click="openMergeModal"
        />
        <woot-button
          v-if="isAdmin"
          v-tooltip="$t('DELETE_CONTACT.BUTTON_LABEL')"
          title="$t('DELETE_CONTACT.BUTTON_LABEL')"
          class="delete-contact"
          icon="ion-trash-a"
          variant="smooth"
          size="small expanded"
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
    <woot-confirm-delete-modal
      v-if="showDeleteModal"
      :show.sync="showDeleteModal"
      :title="$t('DELETE_CONTACT.CONFIRM.TITLE')"
      :message="confirmDeleteMessage"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
      :confirm-value="contact.name"
      :confirm-place-holder-text="confirmPlaceHolderText"
      @on-confirm="confirmDeletion"
      @on-close="closeDelete"
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
    showNewMessage: {
      type: Boolean,
      default: false,
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
    additionalAttributes() {
      return this.contact.additional_attributes || {};
    },
    socialProfiles() {
      const {
        social_profiles: socialProfiles,
        screen_name: twitterScreenName,
      } = this.additionalAttributes;

      return { twitter: twitterScreenName, ...(socialProfiles || {}) };
    },
    // Delete Modal
    deleteConfirmText() {
      return `${this.$t('DELETE_CONTACT.CONFIRM.YES')} ${this.contact.name}`;
    },
    deleteRejectText() {
      return `${this.$t('DELETE_CONTACT.CONFIRM.NO')} ${this.contact.name}`;
    },
    confirmDeleteMessage() {
      return `${this.$t('DELETE_CONTACT.CONFIRM.MESSAGE')} ${
        this.contact.name
      } ?`;
    },
    confirmPlaceHolderText() {
      return `${this.$t('DELETE_CONTACT.CONFIRM.PLACE_HOLDER', {
        contactName: this.contact.name,
      })}`;
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
    async deleteContact({ id }) {
      try {
        await this.$store.dispatch('contacts/delete', id);
        this.$emit('panel-close');
        this.showAlert(this.$t('DELETE_CONTACT.API.SUCCESS_MESSAGE'));
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

.contact--name {
  text-transform: capitalize;
  white-space: normal;
}

.contact--metadata {
  margin-bottom: var(--space-small);
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

.button--contact-menu {
  position: absolute;
  right: var(--space-normal);
  top: 0;
}
</style>
