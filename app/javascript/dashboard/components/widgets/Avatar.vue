<template>
  <div :class="avatarClass" :style="style" aria-hidden="true">
    <slot>
      <fluent-icon v-if="isSentByBot" icon="bot" size="12" />
      <span v-else>{{ userInitial }}</span>
    </slot>
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
      let initials = parts.reduce((acc, curr) => acc + curr.charAt(0), '');

      if (initials.length > 2 && initials.search(/[A-Z]/) !== -1) {
        initials = initials.replace(/[a-z]+/g, '');
      }
      initials = initials.substring(0, 2).toUpperCase();

      return initials;
    },
    isSentByBot() {
      return this.username === 'Bot';
    },
    avatarClass() {
      const avatarColor = this.isSentByBot
        ? 'avatar-bot-color'
        : 'avatar-color';
      return `avatar-container ${avatarColor}`;
    },
  },
};
</script>

<style scoped>
@tailwind components;
@layer components {
  .avatar-color {
    @apply bg-gradient-to-t from-woot-100 to-woot-75 text-woot-600;
  }

  .avatar-bot-color {
    @apply bg-gradient-to-t from-blue-100 to-blue-75 text-blue-400;
  }

  .dark .avatar-color {
    @apply bg-gradient-to-t from-woot-500 to-woot-400 text-woot-50;
  }

  .dark .avatar-bot-color {
    @apply bg-gradient-to-t from-blue-500 to-blue-400 text-blue-50;
  }
}
.avatar-container {
  @apply flex leading-[100%] font-medium items-center justify-center text-center cursor-default;
}
</style>
