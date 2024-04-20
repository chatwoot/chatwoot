<template>
  <div
    class="rounded-xl h-[72px] w-[72px] flex leading-[100%] font-medium items-center justify-center text-center cursor-default bg-ash-200 text-ash-900"
    :style="style"
    aria-hidden="true"
  >
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
      let initials = parts.reduce((acc, curr) => acc + curr.charAt(0), '');

      if (initials.length > 2 && initials.search(/[A-Z]/) !== -1) {
        initials = initials.replace(/[a-z]+/g, '');
      }
      initials = initials.substring(0, 2).toUpperCase();

      return initials;
    },
  },
};
</script>
