<template>
  <div class="medium-3 bg-white contact--panel">
    <div class="contact--profile">
      <div class="contact--info">
        <thumbnail
          :src="contactImage"
          size="56px"
          :badge="contact.channel"
          :username="contact.name"
        />
        <div class="contact--details">
          <div class="contact--name">
            {{ contact.name }}
          </div>
          <div class="contact--email">
            {{ contact.email || '' }}
          </div>
          <div class="contact--location">
            {{ contact.location || '' }}
          </div>
        </div>
      </div>
      <div v-if="contact.bio" class="contact--bio">
        {{ contact.bio }}
      </div>
    </div>
    <div class="contact-section--header">
      <span>Conversation Details</span>
    </div>
    <div v-if="browser" class="conversation--details">
      <div v-if="browser.browser_name" class="conv-details--item">
        <div class="conv-details--item__label">
          Browser
        </div>
        <div class="conv-details--item__value">
          {{ browserName }}
        </div>
      </div>
      <div v-if="browser.platform_name" class="conv-details--item">
        <div class="conv-details--item__label">
          Operating System
        </div>
        <div class="conv-details--item__value">
          {{ platformName }}
        </div>
      </div>
      <div v-if="referer" class="conv-details--item">
        <div class="conv-details--item__label">
          Conversation initaition URL
        </div>
        <div class="conv-details--item__value">
          {{ referer }}
        </div>
      </div>
      <div v-if="initiatedAt" class="conv-details--item">
        <div class="conv-details--item__label">
          Timezone
        </div>
        <div class="conv-details--item__value">
          {{ initiatedAt.zone }}
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

export default {
  components: {
    Thumbnail,
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
    }),
    browser() {
      const { meta: { additional_attributes: additionalAttributes } = {} } =
        this.currentChat || {};
      return additionalAttributes ? additionalAttributes.browser : {};
    },
    referer() {
      const { meta: { additional_attributes: additionalAttributes } = {} } =
        this.currentChat || {};
      return additionalAttributes ? additionalAttributes.referer : {};
    },
    initiatedAt() {
      const { meta: { additional_attributes: additionalAttributes } = {} } =
        this.currentChat || {};
      return additionalAttributes ? additionalAttributes.initiated_at : {};
    },
    browserName() {
      return `${this.browser.browser_name || ''} ${this.browser
        .browser_version || ''}`;
    },
    platformName() {
      return `${this.browser.platform_name || ''} ${this.browser
        .platform_version || ''}`;
    },
    contact() {
      const { meta: { sender = {} } = {} } = this.currentChat || {};
      return sender;
    },
    contactImage() {
      return `/uploads/avatar/contact/${this.contact.id}/profilepic.jpeg`;
    },
  },
  mounted() {
    this.$store.dispatch('getContact', {
      id: this.contact.id,
      setSelectedContact: true,
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
}

.contact--profile {
  width: 100%;
  padding: $space-normal $space-medium;
  align-items: center;
  border-bottom: 1px solid $color-border;
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
  font-weight: $font-weight-bold;
  font-size: $font-size-default;
}

.contact--email {
  text-decoration: underline;
}

.contact--bio {
  margin-top: $space-normal;
}

.contact-section--header {
  background: $color-background;
  width: 100%;
  font-size: $font-size-mini;
  padding: $space-one $space-medium;
  border-bottom: 1px solid $color-border;
  text-transform: uppercase;
  font-weight: 500;
}

.conversation--details {
  padding: $space-normal $space-medium;
  width: 100%;
}

.conv-details--item {
  margin-bottom: $space-normal;
  .conv-details--item__label {
    font-style: italic;
    margin-bottom: $space-micro;
  }

  .conv-details--item__value {
    word-break: break-all;
  }
}
</style>
