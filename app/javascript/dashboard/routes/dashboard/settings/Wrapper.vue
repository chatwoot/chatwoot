<template>
  <div class="view-box columns bg-light">
    <settings-header
      button-route="new"
      :icon="icon"
      :header-title="$t(headerTitle)"
      :button-text="$t(headerButtonText)"
      :show-back-button="showBackButton"
      :show-new-button="showNewButton"
    />
    <keep-alive>
      <router-view></router-view>
    </keep-alive>
  </div>
</template>

<script>
/* eslint no-console: 0 */
import SettingsHeader from './SettingsHeader';

export default {
  components: {
    SettingsHeader,
  },
  props: {
    headerTitle: String,
    headerButtonText: String,
    icon: String,
    newButtonRoutes: {
      type: Array,
      default: () => [],
    },
    showBackButton: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {};
  },
  computed: {
    currentPage() {
      return this.$store.state.route.name;
    },
    showNewButton() {
      return this.newButtonRoutes.length !== 0 && !this.showBackButton;
    },
  },
};
</script>
