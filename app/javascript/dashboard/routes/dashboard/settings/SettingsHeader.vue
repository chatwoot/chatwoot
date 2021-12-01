<template>
  <div class="settings-header">
    <h1 class="page-title">
      <woot-sidemenu-icon></woot-sidemenu-icon>
      <back-button
        v-if="showBackButton"
        :button-label="backButtonLabel"
        :back-url="backUrl"
      />
      <fluent-icon v-if="icon" :icon="icon" :class="iconClass" />
      <slot></slot>
      <span>{{ headerTitle }}</span>
    </h1>
    <router-link
      v-if="showNewButton && isAdmin"
      :to="buttonRoute"
      class="button success button--fixed-right-top"
    >
      <fluent-icon icon="add-circle" />
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
    backButtonLabel: {
      type: String,
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
