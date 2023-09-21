<template>
  <div
    class="bg-slate-900 dark:bg-slate-800 rounded-md drop-shadow-md mb-4 max-w-[40rem] inline-flex items-center min-w-[22rem] py-3 px-4"
    :class="isActionPresent ? 'justify-between' : 'justify-center'"
  >
    <div class="text-sm font-medium text-white">
      {{ message }}
    </div>
    <div v-if="isActionPresent" class="ml-4">
      <router-link v-if="action.type == 'link'" :to="action.to" class="">
        {{ action.message }}
      </router-link>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    message: { type: String, default: '' },
    action: {
      type: Object,
      default: () => ({}),
    },
    showButton: Boolean,
    duration: {
      type: [String, Number],
      default: 3000,
    },
  },
  computed: {
    isActionPresent() {
      return this.action && this.action.message;
    },
  },
};
</script>
