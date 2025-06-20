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

<template>
  <button
    class="bg-n-background cursor-pointer flex flex-col justify-end transition-all duration-200 ease-in -m-px py-4 px-0 items-center border border-solid border-n-weak hover:border-n-brand hover:shadow-md hover:z-50 disabled:opacity-60"
  >
    <img :src="src" :alt="title" class="w-1/2 my-4 mx-auto" />
    <h3 class="text-n-slate-12 text-base text-center capitalize">
      {{ title }}
    </h3>
  </button>
</template>

<style scoped lang="scss">
.inactive {
  img {
    filter: grayscale(100%);
  }

  &:hover {
    @apply border-transparent shadow-none cursor-not-allowed;
  }
}
</style>
