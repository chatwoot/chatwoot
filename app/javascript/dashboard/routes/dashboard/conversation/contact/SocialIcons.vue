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
        { key: 'instagram', icon: 'instagram', link: 'https://instagram.com/' },
        { key: 'telegram', icon: 'telegram', link: 'https://t.me/' },
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

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <div v-if="availableProfiles.length" class="flex items-end gap-3 mx-0 my-2">
    <a
      v-for="profile in availableProfiles"
      :key="profile.key"
      :href="`${profile.link}${socialProfiles[profile.key]}`"
      target="_blank"
      rel="noopener noreferrer nofollow"
    >
      <fluent-icon
        :icon="`brand-${profile.key}`"
        size="16"
        class="text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-200"
      />
    </a>
  </div>
</template>
