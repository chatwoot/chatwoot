<template>
  <div class="settings-header">
    <h1 class="page-title">
      <woot-sidemenu-icon></woot-sidemenu-icon>
      <back-button v-if="!showButton"></back-button>
      <i :class="iconClass"></i>
      <span>{{ headerTitle }}</span>
    </h1>
    <router-link
      v-if="showNewButton && showButton && isAdmin"
      :to="buttonRoute"
      class="button icon success nice button--fixed-right-top"
    >
      <i class="icon ion-android-add-circle"></i>
      {{ buttonText }}
    </router-link>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import BackButton from '../../../components/widgets/BackButton';

export default {
  components: {
    BackButton,
  },
  props: {
    headerTitle: {
      default: '',
      type: String,
    },
    buttonRoute: {
      default: '',
      type: String,
    },
    buttonText: {
      default: '',
      type: String,
    },
    icon: {
      default: '',
      type: String,
    },
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
    ...mapGetters({
      currentUser: 'getCurrentUser',
    }),
    iconClass() {
      return `icon ${this.icon} header--icon`;
    },
    isAdmin() {
      const { role } = this.currentUser;
      return role === 'administrator';
    },
  },
};
</script>
