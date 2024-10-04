<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import SocialIcons from 'dashboard/routes/dashboard/conversation/contact/SocialIcons.vue';

export default {
  components: {
    Thumbnail,
    SocialIcons,
  },
  props: {
    contact: {
      type: Object,
      default: () => ({}),
    },
  },
  emits: ['edit', 'message'],

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
    company() {
      const { company = {} } = this.contact;
      return company;
    },
  },
  methods: {
    onEditClick() {
      this.$emit('edit');
    },
    onNewMessageClick() {
      this.$emit('message');
    },
  },
};
</script>

<template>
  <div class="contact--intro">
    <Thumbnail
      :src="contact.thumbnail"
      size="64px"
      :username="contact.name"
      :status="contact.availability_status"
    />

    <div class="contact--details">
      <h2 class="text-lg contact--name">
        {{ contact.name }}
      </h2>
      <h3 class="text-base contact--work">
        {{ contact.title }}
        <i v-if="company.name" class="i-lucide-circle-minus" />
        <span class="company-name">{{ company.name }}</span>
      </h3>
      <p v-if="additionalAttributes.description" class="contact--bio">
        {{ additionalAttributes.description }}
      </p>
      <SocialIcons :social-profiles="socialProfiles" />
    </div>
    <div class="contact-actions">
      <woot-button
        class="new-message"
        size="small expanded"
        icon="ion-paper-airplane"
        @click="onNewMessageClick"
      >
        {{ $t('CONTACT_PANEL.NEW_MESSAGE') }}
      </woot-button>
      <woot-button
        variant="hollow"
        size="small expanded"
        icon="edit"
        @click="onEditClick"
      >
        {{ $t('EDIT_CONTACT.BUTTON_LABEL') }}
      </woot-button>
    </div>
  </div>
</template>

<style scoped lang="scss">
.contact--details {
  margin-top: var(--space-small);
}

.contact--work {
  color: var(--color-body);

  .icon {
    font-size: var(--font-size-nano);
    vertical-align: middle;
  }
}

.contact--name {
  text-transform: capitalize;
  font-weight: var(--font-weight-bold);
}

.contact--bio {
  margin: var(--space-smaller) 0 0;
}

.button.new-message {
  margin-right: var(--space-small);
}

.contact-actions {
  display: flex;
  align-items: center;
  width: 100%;
  margin-top: var(--space-small);
}
</style>
