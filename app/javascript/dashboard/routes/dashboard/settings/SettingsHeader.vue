<script>
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
    icon: {
      default: '',
      type: String,
    },
    showBackButton: { type: Boolean, default: false },
    backUrl: {
      type: [String, Object],
      default: '',
    },
    backButtonLabel: {
      type: String,
      default: '',
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
    class="flex justify-between items-center h-20 min-h-[3.5rem] px-6 py-2 bg-n-surface-1"
  >
    <h1 class="flex items-center mb-0 text-2xl text-n-slate-12">
      <BackButton
        v-if="showBackButton"
        :button-label="backButtonLabel"
        :back-url="backUrl"
        class="ltr:mr-4 rtl:ml-4"
      />

      <slot />
      <span class="text-xl font-medium text-n-slate-12">
        {{ headerTitle }}
      </span>
    </h1>
  </div>
</template>
