<script>
export default {
  props: {
    title: { type: String, default: '' },
    message: { type: String, default: '' },
  },
};
</script>

<template>
  <div class="empty-state py-16 px-1 ml-0 mr-0">
    <h3
      v-if="title"
      class="text-s-primary block text-center w-full text-xl font-medium"
    >
      {{ title }}
    </h3>
    <p
      v-if="message"
      class="block text-center text-s-muted my-4 mx-auto w-[90%]"
    >
      {{ message }}
    </p>
    <slot />
  </div>
</template>
