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
      <div v-if="!showNewMessage">
        <div>
          <woot-button
            class="edit-contact"
            variant="link"
            size="small"
            @click="toggleEditModal"
          >
            {{ $t('EDIT_CONTACT.BUTTON_LABEL') }}
          </woot-button>
        </div>
        <div>
          <woot-button
            class="edit-contact"
            color-scheme="secondary"
            variant="link"
            size="small"
            @click="openMergeModal"
          >
            {{ $t('CONTACT_PANEL.MERGE_CONTACT') }}
          </woot-button>
        </div>
      </div>
      <div v-else class="contact-actions">
        <woot-button
          class="new-message"
          size="small expanded"
          @click="toggleConversationModal"
        >
          {{ $t('CONTACT_PANEL.NEW_MESSAGE') }}
        </woot-button>
        <woot-button
          variant="smooth"
          size="small expanded"
          @click="toggleEditModal"
        >
          {{ $t('EDIT_CONTACT.BUTTON_LABEL') }}
        </woot-button>
      </div>
      <edit-contact
        v-if="showEditModal"
        :show="showEditModal"
        :contact="contact"
        @cancel="toggleEditModal"
      />
      <new-conversation
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

export default {
  components: {
    ContactInfoRow,
    EditContact,
    Thumbnail,
    SocialIcons,
    NewConversation,
    ContactMergeModal,
  },
  mixins: [clickaway],
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
    };
  },
  computed: {
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
.button.edit-contact {
  margin-left: var(--space-medium);
}

.button.new-message {
  margin-right: var(--space-small);
}

.contact-actions {
  display: flex;
  align-items: center;
  width: 100%;
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
