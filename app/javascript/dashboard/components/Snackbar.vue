<template>
  <div>
    <div
      class="shadow-sm bg-slate-800 dark:bg-slate-700 rounded-[4px] items-center gap-3 inline-flex mb-2 max-w-[25rem] min-h-[1.875rem] min-w-[15rem] px-6 py-3 text-left"
    >
      <div class="text-white dark:text-white text-sm font-medium">
        {{ message }}
      </div>
      <div v-if="action">
        <router-link
          v-if="action.type == 'link'"
          :to="action.to"
          class="text-woot-500 dark:text-woot-500 cursor-pointer font-medium hover:text-woot-600 dark:hover:text-woot-600 select-none"
        >
          {{ action.message }}
        </router-link>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    message: { type: String, default: '' },
    action: {
      type: Object,
      default: () => {},
    },
    showButton: Boolean,
    duration: {
      type: [String, Number],
      default: 3000,
    },
  },
  data() {
    return {
      toggleAfterTimeout: false,
    };
  },
  mounted() {},
  methods: {},
};
</script>
