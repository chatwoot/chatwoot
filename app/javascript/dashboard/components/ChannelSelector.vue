<template>
  <button
    class="sm:w-[50%] md:w-[34%] lg:w-[25%] channel"
    @click="$emit('click')"
  >
    <img :src="src" :alt="title" />
    <h3 class="channel__title">
      {{ title }}
    </h3>
  </button>
</template>

<script>
export default {
  props: {
    title: {
      type: String,
      required: true,
    },
    src: {
      type: String,
      required: true,
    },
  },
};
</script>

<style scoped lang="scss">
.inactive {
  img {
    filter: grayscale(100%);
  }

  &.channel:hover {
    @apply border-transparent shadow-none cursor-not-allowed;
  }
}

.channel {
  @apply bg-white dark:bg-slate-900 cursor-pointer flex flex-col transition-all duration-200 ease-in -m-px py-4 px-0 items-center border border-solid border-slate-25 dark:border-slate-800;

  &:hover {
    @apply border-woot-500 dark:border-woot-500 shadow-md z-50;
  }

  &.disabled {
    @apply opacity-60;
  }

  img {
    @apply w-[50%] my-4 mx-auto;
  }

  .channel__title {
    @apply text-slate-800 dark:text-slate-100 text-base text-center capitalize;
  }

  p {
    @apply text-slate-600 dark:text-slate-300 w-full text-sm;
  }
}
</style>
