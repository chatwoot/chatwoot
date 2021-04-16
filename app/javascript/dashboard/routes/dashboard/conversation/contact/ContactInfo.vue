<template>
  <div class="contact--profile">
    <div class="contact--info">
      <thumbnail
        :src="contact.thumbnail"
        size="64px"
        :badge="channelType"
        :username="contact.name"
        :status="contact.availability_status"
      />

      <div class="contact--details">
        <div class="contact--name">
          {{ contact.name }}
        </div>
        <div v-if="additionalAttributes.description" class="contact--bio">
          {{ additionalAttributes.description }}
        </div>
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
      <woot-button
        v-if="!showNewMessage"
        class="edit-contact"
        variant="clear link"
        size="small"
        @click="toggleEditModal"
      >
        {{ $t('EDIT_CONTACT.BUTTON_LABEL') }}
      </woot-button>
      <div v-else class="contact-actions">
        <woot-button
          class="new-message"
          size="small expanded"
          @click="toggleConversationModal"
        >
          {{ $t('CONTACT_PANEL.NEW_MESSAGE') }}
        </woot-button>
        <woot-button
          variant="hollow"
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
    </div>
  </div>
</template>
<script>
import ContactInfoRow from './ContactInfoRow';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import SocialIcons from './SocialIcons';
import EditContact from './EditContact';
import NewConversation from './NewConversation';

export default {
  components: {
    ContactInfoRow,
    EditContact,
    Thumbnail,
    SocialIcons,
    NewConversation,
  },
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
    toggleEditModal() {
      this.showEditModal = !this.showEditModal;
    },
    toggleConversationModal() {
      this.showConversationModal = !this.showConversationModal;
    },
  },
};
</script>

<style scoped lang="scss">
@import '~dashboard/assets/scss/variables';
@import '~dashboard/assets/scss/mixins';
.contact--profile {
  align-items: flex-start;
  padding: var(--space-normal) var(--space-normal);

  .user-thumbnail-box {
    margin-right: $space-normal;
  }
}

.contact--details {
  margin-top: $space-small;
  width: 100%;

  p {
    margin-bottom: 0;
  }
}

.contact--info {
  align-items: flex-start;
  display: flex;
  flex-direction: column;
  text-align: left;
}

.contact--name {
  @include text-ellipsis;
  text-transform: capitalize;
  white-space: normal;
  font-weight: $font-weight-bold;
  font-size: $font-size-default;
}

.contact--bio {
  margin: $space-small 0 0;
}

.contact--metadata {
  margin: var(--space-normal) 0 0;
}

.social--icons {
  i {
    font-size: $font-weight-normal;
  }
}
.contact-actions {
  margin: var(--space-small) 0;
}
.button.edit-contact {
  margin-left: var(--space-two);
  padding-left: var(--space-micro);
}

.button.new-message {
  margin-right: var(--space-small);
}

.contact-actions {
  display: flex;
  align-items: center;
  width: 100%;
}
</style>
