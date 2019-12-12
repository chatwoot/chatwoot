<template>
  <div class="settings-header">
    <h1 class="page-title">
      <woot-sidemenu-icon></woot-sidemenu-icon>
      <back-button v-if="!showButton"></back-button>
      <i :class="iconClass"></i>
      <span>{{ headerTitle }}</span>
    </h1>
    <router-link
      v-if="showNewButton && showButton && currentRole"
      :to="buttonRoute"
      class="button icon success nice"
    >
      <i class="icon ion-android-add-circle"></i>
      {{ buttonText }}
    </router-link>
  </div>
</template>
<script>
import BackButton from '../../../components/widgets/BackButton';
import Auth from '../../../api/auth';

export default {
  components: {
    BackButton,
  },
  props: {
    headerTitle: String,
    buttonRoute: String,
    buttonText: String,
    icon: String,
    showButton: Boolean,
    showNewButton: Boolean,
    hideButtonRoutes: {
      type: Array,
      default() {
        return ['agent_list', 'settings_inbox_list'];
      },
    },
  },
  computed: {
    iconClass() {
      return `icon ${this.icon} header--icon`;
    },
    currentRole() {
      const { role } = Auth.getCurrentUser();
      return role === 'administrator';
    },
  },
};
</script>
