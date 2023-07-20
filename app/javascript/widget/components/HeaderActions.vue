<template>
  <div class="flex items-end gap-2">
    <button
      v-if="showPopoutButton"
      class="inline-flex h-10 w-10 rounded items-center justify-center border border-1 border-slate-200 hover:bg-slate-75"
      @click="popoutChatWindow"
    >
      <fluent-icon
        icon="open"
        size="16"
        :class="$dm('text-slate-900', 'dark:text-slate-50')"
      />
    </button>
    <button
      v-if="canLeaveConversation && hasEndConversationEnabled"
      class="inline-flex h-10 w-10 rounded items-center justify-center border border-1 border-slate-200 hover:bg-slate-75"
      :title="$t('END_CONVERSATION')"
      @click="resolveConversation"
    >
      <fluent-icon
        icon="checkmark"
        size="16"
        :class="$dm('text-slate-900', 'dark:text-slate-50')"
      />
    </button>
  </div>
</template>
<script>
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import darkModeMixin from 'widget/mixins/darkModeMixin';
import configMixin from 'widget/mixins/configMixin';

export default {
  name: 'HeaderActions',
  components: { FluentIcon },
  mixins: [configMixin, darkModeMixin],
  props: {
    showPopoutButton: {
      type: Boolean,
      default: false,
    },
  },
  computed: {},
  methods: {
    resolveConversation() {
      this.$store.dispatch('conversation/resolveConversation');
    },
    popoutChatWindow() {
      this.$emit('popout');
    },
  },
};
</script>
<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.actions {
  button {
    margin-left: $space-normal;
  }

  span {
    color: $color-heading;
    font-size: $font-size-large;
  }

  .close-button {
    display: none;
  }
}
</style>
