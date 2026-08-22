// Channel gating (installation OAuth app IDs + feature flags) has been removed
// so that every channel is always shown and selectable in the onboarding flow.
// Mirrors the change in components/widgets/ChannelItem.vue.
export function useChannelConfig() {
  const isConfigured = () => true;

  return { isConfigured };
}
