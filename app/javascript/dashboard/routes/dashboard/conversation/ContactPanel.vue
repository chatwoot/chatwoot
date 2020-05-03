<template>
  <div class="medium-3 bg-white contact--panel">
    <div class="contact--profile">
      <span class="close-button" @click="onPanelToggle">
        <i class="ion-close-round"></i>
      </span>
      <div class="contact--info">
        <thumbnail
          :src="contact.thumbnail"
          size="56px"
          :badge="contact.channel"
          :username="contact.name"
          :status="contact.availability_status"
        />
        <div class="contact--details">
          <div class="contact--name">
            {{ contact.name }}
          </div>
          <a
            v-if="contact.email"
            :href="`mailto:${contact.email}`"
            class="contact--email"
          >
            {{ contact.email }}
          </a>
          <a
            v-if="contact.phone_number"
            :href="`tel:${contact.phone_number}`"
            class="contact--email"
          >
            {{ contact.phone_number }}
          </a>

          <div
            v-if="
              contact.additional_attributes &&
                contact.additional_attributes.screen_name
            "
            class="contact--location"
          >
            {{ `@${contact.additional_attributes.screen_name}` }}
          </div>
          <div class="contact--location">
            {{ contact.location }}
          </div>
        </div>
      </div>
      <div v-if="contact.bio" class="contact--bio">
        {{ contact.bio }}
      </div>
      <div
        v-if="
          contact.additional_attributes &&
            contact.additional_attributes.description
        "
        class="contact--bio"
      >
        {{ contact.additional_attributes.description }}
      </div>
    </div>
    <conversation-labels :conversation-id="conversationId" />
    <contact-conversations
      v-if="contact.id"
      :contact-id="contact.id"
      :conversation-id="conversationId"
    />
    <div v-if="browser" class="conversation--details">
      <contact-details-item
        v-if="browser.browser_name"
        :title="$t('CONTACT_PANEL.BROWSER')"
        :value="browserName"
        icon="ion-ios-world-outline"
      />
      <contact-details-item
        v-if="browser.platform_name"
        :title="$t('CONTACT_PANEL.OS')"
        :value="platformName"
        icon="ion-laptop"
      />
      <contact-details-item
        v-if="referer"
        :title="$t('CONTACT_PANEL.INITIATED_FROM')"
        :value="referer"
        icon="ion-link"
      />
      <contact-details-item
        v-if="initiatedAt"
        :title="$t('CONTACT_PANEL.INITIATED_AT')"
        :value="initiatedAt.timestamp"
        icon="ion-clock"
      />
    </div>
  </div>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import ContactConversations from './ContactConversations.vue';
import ContactDetailsItem from './ContactDetailsItem.vue';
import ConversationLabels from './ConversationLabels.vue';

export default {
  components: {
    ContactConversations,
    ContactDetailsItem,
    ConversationLabels,
    Thumbnail,
  },
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
    onToggle: {
      type: Function,
      default: () => {},
    },
  },
  computed: {
    currentConversationMetaData() {
      return this.$store.getters[
        'conversationMetadata/getConversationMetadata'
      ](this.conversationId);
    },
    additionalAttributes() {
      return this.currentConversationMetaData.additional_attributes || {};
    },
    browser() {
      return this.additionalAttributes.browser || {};
    },
    referer() {
      return this.additionalAttributes.referer;
    },
    initiatedAt() {
      return this.additionalAttributes.initiated_at;
    },
    browserName() {
      return `${this.browser.browser_name || ''} ${this.browser
        .browser_version || ''}`;
    },
    platformName() {
      const {
        platform_name: platformName,
        platform_version: platformVersion,
      } = this.browser;
      return `${platformName || ''} ${platformVersion || ''}`;
    },
    contactId() {
      return this.currentConversationMetaData.contact?.id;
    },
    contact() {
      return this.$store.getters['contacts/getContact'](this.contactId);
    },
  },
  watch: {
    contactId(newContactId, prevContactId) {
      if (newContactId && newContactId !== prevContactId) {
        this.$store.dispatch('contacts/show', { id: newContactId });
      }
    },
  },
  mounted() {
    this.$store.dispatch('contacts/show', { id: this.contactId });
  },
  methods: {
    onPanelToggle() {
      this.onToggle();
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables';
@import '~dashboard/assets/scss/mixins';

.contact--panel {
  @include border-normal-left;
  font-size: $font-size-small;
  overflow-y: auto;
  background: white;
  overflow: auto;
  position: relative;
}

.close-button {
  position: absolute;
  right: $space-normal;
  top: $space-slab;
  font-size: $font-size-default;
  color: $color-heading;
}
.contact--profile {
  padding: $space-medium $space-normal 0 $space-medium;
  align-items: center;
  .user-thumbnail-box {
    margin-right: $space-normal;
  }
}

.contact--details {
  p {
    margin-bottom: 0;
  }
}

.contact--info {
  display: flex;
  align-items: center;
}

.contact--name {
  @include text-ellipsis;
  text-transform: capitalize;

  font-weight: $font-weight-bold;
  font-size: $font-size-default;
}

.contact--email {
  @include text-ellipsis;

  color: $color-body;
  display: block;
  line-height: $space-medium;
  text-decoration: underline;
}

.contact--bio {
  margin-top: $space-normal;
}

.conversation--details {
  padding: $space-two $space-normal $space-two $space-medium;
}

.conversation--labels {
  padding: $space-medium;

  .icon {
    margin-right: $space-micro;
    font-size: $font-size-micro;
    color: #fff;
  }

  .label {
    color: #fff;
    padding: 0.2rem;
  }
}
</style>
