<template>
  <div class="medium-3 bg-white contact--panel">
    <div class="contact--profile">
      <span class="close-button" @click="onPanelToggle">
        <i class="ion-chevron-right" />
      </span>
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
      <div class="contact--actions">
        <button
          v-if="!currentChat.muted"
          class="button small clear contact--mute small-6"
          @click="mute"
        >
          {{ $t('CONTACT_PANEL.MUTE_CONTACT') }}
        </button>
      </div>
    </div>
    <div v-if="browser.browser_name" class="conversation--details">
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
    <conversation-labels :conversation-id="conversationId" />
    <contact-conversations
      v-if="contact.id"
      :contact-id="contact.id"
      :conversation-id="conversationId"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import ContactConversations from './ContactConversations.vue';
import ContactDetailsItem from './ContactDetailsItem.vue';
import ConversationLabels from './labels/LabelBox.vue';

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
    ...mapGetters({
      currentChat: 'getSelectedChat',
    }),
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
    channelType() {
      return this.currentChat.meta?.channel;
    },
    contactId() {
      return this.currentChat.meta?.sender?.id;
    },
    contact() {
      return this.$store.getters['contacts/getContact'](this.contactId);
    },
  },
  watch: {
    conversationId(newConversationId, prevConversationId) {
      if (newConversationId && newConversationId !== prevConversationId) {
        this.getContactDetails();
      }
    },
    contactId() {
      this.getContactDetails();
    },
  },
  mounted() {
    this.getContactDetails();
  },
  methods: {
    onPanelToggle() {
      this.onToggle();
    },
    mute() {
      this.$store.dispatch('muteConversation', this.conversationId);
    },
    getContactDetails() {
      if (this.contactId) {
        this.$store.dispatch('contacts/show', { id: this.contactId });
      }
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables';
@import '~dashboard/assets/scss/mixins';

.contact--panel {
  @include border-normal-left;

  background: white;
  font-size: $font-size-small;
  overflow-y: auto;
  overflow: auto;
  position: relative;
  padding: $space-normal;
}

.close-button {
  position: absolute;
  right: $space-normal;
  top: $space-slab;
  font-size: $font-size-default;
  color: $color-heading;
}

.contact--profile {
  align-items: center;
  padding: $space-medium 0 $space-one;

  .user-thumbnail-box {
    margin-right: $space-normal;
  }
}

.contact--details {
  margin-top: $space-small;

  p {
    margin-bottom: 0;
  }
}

.contact--info {
  align-items: center;
  display: flex;
  flex-direction: column;
  text-align: center;
}

.contact--name {
  @include text-ellipsis;
  text-transform: capitalize;

  font-weight: $font-weight-bold;
  font-size: $font-size-default;
}

.contact--email {
  @include text-ellipsis;

  color: $color-gray;
  display: block;
  line-height: $space-medium;

  &:hover {
    color: $color-woot;
  }
}

.contact--bio {
  margin-top: $space-normal;
}

.conversation--details {
  border-top: 1px solid $color-border-light;
  padding: $space-large $space-normal;
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

.contact-conversation--panel {
  border-top: 1px solid $color-border-light;
}

.contact--mute {
  color: $alert-color;
  display: block;
  text-align: center;
}

.contact--actions {
  display: flex;
  justify-content: center;
}
</style>
