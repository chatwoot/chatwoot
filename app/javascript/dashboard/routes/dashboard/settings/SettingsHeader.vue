<template>
  <div
    class="flex justify-between items-center h-14 min-h-[3.5rem] px-4 py-2 bg-white dark:bg-slate-900 border-b border-slate-50 dark:border-slate-800/50"
  >
    <h1
      class="flex items-center mb-0 text-2xl text-slate-900 dark:text-slate-100"
    >
      <woot-sidemenu-icon v-if="showSidemenuIcon" />
      <back-button
        v-if="showBackButton"
        :button-label="backButtonLabel"
        :back-url="backUrl"
        class="ml-2 mr-4"
      />
      <fluent-icon
        v-if="icon"
        :icon="icon"
        :class="iconClass"
        class="hidden ml-1 mr-2 rtl:ml-2 rtl:mr-1 md:block"
      />
      <slot />
      <span class="text-2xl font-medium text-slate-900 dark:text-slate-100">
        {{ headerTitle }}
      </span>
    </h1>
    <router-link
      v-if="showNewButton && isAdmin"
      :to="buttonRoute"
      class="button success button--fixed-top px-3.5 py-1 rounded-[5px] flex gap-2"
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
import { useAdmin } from 'dashboard/composables/useAdmin';
import BackButton from '../../../components/widgets/BackButton.vue';

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
    showSidemenuIcon: {
      type: Boolean,
      default: true,
    },
  },
  setup() {
    const { isAdmin } = useAdmin();
    return {
      isAdmin,
    };
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
