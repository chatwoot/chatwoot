<template>
  <div v-if="availableProfiles.length" class="social--icons">
    <a
      v-for="profile in availableProfiles"
      :key="profile.key"
      :href="`${profile.link}${socialProfiles[profile.key]}`"
      target="_blank"
      rel="noopener noreferrer nofollow"
      class="contact--social-icon"
    >
      <i :class="`ion-social-${profile.icon}`" />
    </a>
  </div>
</template>

<script>
export default {
  props: {
    socialProfiles: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      socialMediaLinks: [
        { key: 'facebook', icon: 'facebook', link: 'https://facebook.com/' },
        { key: 'twitter', icon: 'twitter', link: 'https://twitter.com/' },
        { key: 'linkedin', icon: 'linkedin', link: 'https://linkedin.com/' },
        { key: 'github', icon: 'github', link: 'https://github.com/' },
      ],
    };
  },
  computed: {
    availableProfiles() {
      return this.socialMediaLinks.filter(
        mediaLink => !!this.socialProfiles[mediaLink.key]
      );
    },
  },
};
</script>

<style scoped lang="scss">
.social--icons {
  margin-bottom: var(--space-small);
}
.contact--social-icon {
  font-size: var(--font-size-medium);
  padding-right: var(--space-slab);
  color: var(--color-body);
}
</style>
