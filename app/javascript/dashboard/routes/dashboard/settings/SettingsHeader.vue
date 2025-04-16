<script>
import { useAdmin } from 'dashboard/composables/useAdmin';
import BackButton from '../../../components/widgets/BackButton.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    BackButton,
    NextButton,
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
    iconClass() {
      return `icon ${this.icon} header--icon`;
    },
  },
};
</script>

<template>
  <div
    class="flex justify-between items-center h-20 min-h-[3.5rem] px-4 py-2 bg-n-background"
  >
    <h1 class="flex items-center mb-0 text-2xl text-n-slate-12">
      <woot-sidemenu-icon v-if="showSidemenuIcon" />
      <BackButton
        v-if="showBackButton"
        :button-label="backButtonLabel"
        :back-url="backUrl"
        class="ml-2 mr-4"
      />

      <slot />
      <span class="text-xl font-medium text-slate-900 dark:text-slate-100">
        {{ headerTitle }}
      </span>
    </h1>
    <!-- TODO: Remove this when we are not using this -->
    <router-link v-if="showNewButton && isAdmin" :to="buttonRoute">
      <NextButton
        teal
        icon="i-lucide-circle-plus"
        class="button--fixed-top"
        :label="buttonText"
      />
    </router-link>
  </div>
</template>
