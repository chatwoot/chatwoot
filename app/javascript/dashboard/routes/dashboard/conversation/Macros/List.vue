<template>
  <div>
    <p
      v-if="!uiFlags.isFetching && !macros.length"
      class="no-items-error-message"
    >
      {{ $t('MACROS.LIST.404') }}
    </p>
    <woot-loading-state
      v-if="uiFlags.isFetching"
      :message="$t('MACROS.LOADING')"
    />
    <div v-if="!uiFlags.isFetching && macros.length" class="macros-list">
      <macro-item
        v-for="macro in macros"
        :key="macro.id"
        :macro="macro"
        :conversation-id="conversationId"
      />
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import MacroItem from './MacroItem.vue';
export default {
  components: {
    MacroItem,
  },
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
  },
  computed: {
    ...mapGetters({
      macros: ['macros/getMacros'],
      uiFlags: 'macros/getUIFlags',
    }),
  },
  mounted() {
    this.$store.dispatch('macros/get');
  },
};
</script>
<style scoped lang="scss">
.macros-list {
  padding: var(--space-smaller);
}
</style>
