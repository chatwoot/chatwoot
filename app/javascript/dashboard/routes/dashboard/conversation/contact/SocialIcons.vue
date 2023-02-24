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
      <fluent-icon :icon="`brand-${profile.key}`" size="16" />
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
  align-items: flex-end;
  display: flex;
  margin: var(--space-small) 0 var(--space-smaller);
}

.contact--social-icon {
  padding-right: var(--space-slab);
  color: var(--color-body);
}
</style>
