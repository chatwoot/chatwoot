<template>
  <div class="settings-header">
    <h1 class="page-title">
      <back-button v-if="!showButton"></back-button>
      <i :class="icon"></i>
      <span>{{ headerTitle }}</span>
    </h1>
    <router-link
      :to="buttonRoute"
      class="button icon success"
      v-if="showNewButton && showButton && currentRole"
    >
      <i class="icon ion-android-add-circle"></i>
      {{buttonText}}
    </router-link>
  </div>
</template>
<script>
import BackButton from '../../../components/widgets/BackButton';
import Auth from '../../../api/auth';

export default {
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
      return `icon ${this.props.icon}`;
    },
    currentRole() {
      const { role } = Auth.getCurrentUser();
      return role === 'administrator';
    },
  },
  components: {
    BackButton,
  },
};
</script>
