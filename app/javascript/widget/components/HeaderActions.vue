<template>
  <div class="flex items-end gap-2">
    <button
      v-if="showPopoutButton"
      class="inline-flex h-10 w-10 rounded items-center justify-center border border-solid border-slate-200 hover:bg-slate-75 group"
      @click="$emit('popout')"
    >
      <fluent-icon
        icon="open"
        size="16"
        class="group-hover:text-slate-600"
        :class="$dm('text-slate-900', 'dark:text-slate-50')"
      />
    </button>
    <button
      v-if="showResolveButton"
      class="inline-flex h-10 w-10 rounded items-center justify-center border border-solid border-slate-200 hover:bg-slate-75 group"
      :title="$t('END_CONVERSATION')"
      @click="$emit('resolve')"
    >
      <fluent-icon
        icon="checkmark"
        size="16"
        class="group-hover:text-green-600"
        :class="$dm('text-slate-900', 'dark:text-slate-50')"
      />
    </button>
  </div>
</template>
<script>
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import darkModeMixin from 'widget/mixins/darkModeMixin';

export default {
  name: 'HeaderActions',
  components: { FluentIcon },
  mixins: [darkModeMixin],
  props: {
    showPopoutButton: {
      type: Boolean,
      default: false,
    },
    showResolveButton: {
      type: Boolean,
      default: false,
    },
  },
};
</script>
