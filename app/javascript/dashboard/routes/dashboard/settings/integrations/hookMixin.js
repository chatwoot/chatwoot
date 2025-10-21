export default {
  computed: {
    isHookTypeInbox() {
      return this.integration.hook_type === 'inbox';
    },
    hasConnectedHooks() {
      return !!this.integration.hooks.length;
    },
  },
};
