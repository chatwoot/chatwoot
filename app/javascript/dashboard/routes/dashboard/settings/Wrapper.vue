<template>
  <div class="view-box columns bg-light">
    <settings-header
      button-route="new"
      :icon="icon"
      :header-title="$t(headerTitle)"
      :button-text="$t(headerButtonText)"
      :show-back-button="showBackButton"
      :back-url="backUrl"
      :show-new-button="showNewButton"
    />
    <keep-alive v-if="keepAlive">
      <router-view></router-view>
    </keep-alive>
    <router-view v-else></router-view>
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
    keepAlive: {
      type: Boolean,
      default: true,
    },
    newButtonRoutes: {
      type: Array,
      default: () => [],
    },
    showBackButton: {
      type: Boolean,
      default: false,
    },
    backUrl: {
      type: [String, Object],
      default: '',
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
