<template>
  <div>
    <div
      v-if="!uiFlags.isFetching && !macros.length"
      class="macros_list--empty-state"
    >
      <p class="flex h-full items-center flex-col justify-center">
        {{ $t('MACROS.LIST.404') }}
      </p>
      <router-link :to="addAccountScoping('settings/macros')">
        <woot-button
          variant="smooth"
          icon="add"
          size="tiny"
          class="macros_add-button"
        >
          {{ $t('MACROS.HEADER_BTN_TXT') }}
        </woot-button>
      </router-link>
    </div>
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
import accountMixin from 'dashboard/mixins/account.js';

export default {
  components: {
    MacroItem,
  },
  mixins: [accountMixin],
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
.macros_list--empty-state {
  padding: var(--space-slab);
  p {
    margin: 0;
  }
}
.macros_add-button {
  margin: var(--space-small) auto 0;
}
</style>
