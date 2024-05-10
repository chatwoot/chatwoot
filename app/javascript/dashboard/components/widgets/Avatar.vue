<template>
  <div class="avatar-container" :style="style" aria-hidden="true">
    <slot>{{ userInitial }}</slot>
  </div>
</template>

<script>
export default {
  name: 'Avatar',
  props: {
    username: {
      type: String,
      default: '',
    },
    size: {
      type: Number,
      default: 40,
    },
  },
  computed: {
    style() {
      return {
        fontSize: `${Math.floor(this.size / 2.5)}px`,
      };
    },
    userInitial() {
      const parts = this.username.split(/[ -]/);
      let initials = '';

      if (parts.length === 1) {
        initials = parts[0].substring(0, 2);
      } else if (parts.length >= 2) {
        const lastTwoWords = parts.slice(-2);
        initials = lastTwoWords.reduce((acc, curr) => acc + curr.charAt(0), '');
      }

      initials = initials.toUpperCase();

      return initials;
    },
  },
};
</script>

<style scoped>
@tailwind components;
@layer components {
  .avatar-color {
    background-image: linear-gradient(to top, #c2e1ff 0%, #d6ebff 100%);
  }

  .dark-avatar-color {
    background-image: linear-gradient(to top, #135899 0%, #135899 100%);
  }
}
.avatar-container {
  @apply flex leading-[100%] font-medium items-center justify-center text-center cursor-default avatar-color dark:dark-avatar-color text-woot-600 dark:text-woot-200;
}
</style>
