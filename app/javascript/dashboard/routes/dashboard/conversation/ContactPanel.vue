<template>
  <div class="medium-3 bg-white contact--panel">
    <div class="contact--profile">
      <div class="contact--info">
        <thumbnail
          :src="contact.thumbnail"
          size="56px"
          :badge="contact.channel"
          :username="contact.name"
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
          <div class="contact--location">
            {{ contact.location }}
          </div>
        </div>
      </div>
      <div v-if="contact.bio" class="contact--bio">
        {{ contact.bio }}
      </div>
    </div>
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
    <contact-conversations
      v-if="contact.id"
      :contact-id="contact.id"
      :conversation-id="conversationId"
    />

    <conversation-labels :conversation-id="conversationId" />
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
      return this.currentConversationMetaData.contact_id;
    },
    contact() {
      return this.$store.getters['contacts/getContact'](this.contactId);
    },
  },
  watch: {
    contactId(newContactId, prevContactId) {
      if (newContactId && newContactId !== prevContactId) {
        this.$store.dispatch('contacts/show', {
          id: this.currentConversationMetaData.contact_id,
        });
      }
    },
  },
  mounted() {
    this.$store.dispatch('contacts/show', {
      id: this.currentConversationMetaData.contact_id,
    });
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
  background: $color-white;
  overflow: auto;
}

.contact--profile {
  width: 100%;
  padding: $space-normal $space-medium $zero;
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
  padding: $space-medium;
  width: 100%;
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
