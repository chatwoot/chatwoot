<template>
  <div class="settings-header">
    <h1 class="page-title">
      <woot-sidemenu-icon></woot-sidemenu-icon>
      <back-button v-if="showBackButton" :back-url="backUrl"></back-button>
      <i :class="iconClass"></i>
      <span>{{ headerTitle }}</span>
    </h1>
    <router-link
      v-if="showNewButton && isAdmin"
      :to="buttonRoute"
      class="button success button--fixed-right-top"
    >
      <i class="icon ion-android-add-circle"></i>
      <span class="button__content">
        {{ buttonText }}
      </span>
    </router-link>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import BackButton from '../../../components/widgets/BackButton';
import adminMixin from '../../../mixins/isAdmin';

export default {
  components: {
    BackButton,
  },
  mixins: [adminMixin],
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
    showBackButton: { type: Boolean, default: false },
    showNewButton: { type: Boolean, default: false },
    backUrl: {
      type: [String, Object],
      default: '',
    },
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
    }),
    iconClass() {
      return `icon ${this.icon} header--icon`;
    },
  },
};
</script>
