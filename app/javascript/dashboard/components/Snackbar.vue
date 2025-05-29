<script>
export default {
  props: {
    message: { type: String, default: '' },
    action: {
      type: Object,
      default: () => {},
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

<template>
  <div>
    <div
      class="shadow-sm bg-n-slate-12 dark:bg-n-slate-7 rounded-lg items-center gap-3 inline-flex mb-2 max-w-[25rem] min-h-[1.875rem] min-w-[15rem] px-6 py-3 text-left"
    >
      <div class="text-sm font-medium text-white dark:text-white">
        {{ message }}
      </div>
      <div v-if="action">
        <router-link
          v-if="action.type == 'link'"
          :to="action.to"
          class="font-medium cursor-pointer select-none text-n-blue-10 hover:text-n-brand"
        >
          {{ action.message }}
        </router-link>
      </div>
    </div>
  </div>
</template>
