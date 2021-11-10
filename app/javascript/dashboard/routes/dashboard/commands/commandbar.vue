<!-- eslint-disable vue/attribute-hyphenation -->
<template>
  <ninja-keys
    ref="ninjakeys"
    :no-auto-load-md-icons="true"
    hideBreadcrumbs
    :placeholder="placeholder"
  />
</template>

<script>
import 'ninja-keys';
import conversationHotKeysMixin from './conversationHotKeys';
import goToCommandHotKeys from './goToCommandHotKeys';

export default {
  mixins: [conversationHotKeysMixin, goToCommandHotKeys],
  data() {
    return {
      placeholder: this.$t('COMMAND_BAR.SEARCH_PLACEHOLDER'),
    };
  },
  computed: {
    accountId() {
      return this.$store.getters.getCurrentAccountId;
    },
    routeName() {
      return this.$route.name;
    },
    hotKeys() {
      return [...this.conversationHotKeys, ...this.goToCommandHotKeys];
    },
  },
  watch: {
    routeName() {
      this.setCommandbarData();
    },
  },
  mounted() {
    this.setCommandbarData();
  },
  methods: {
    setCommandbarData() {
      this.$refs.ninjakeys.data = this.hotKeys;
    },
  },
};
</script>

<style>
ninja-keys {
  --ninja-accent-color: var(--w-500);
  --ninja-font-family: 'Inter';
  z-index: 9999;
}
</style>
