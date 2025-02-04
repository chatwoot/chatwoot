<template>
  <div
    class="flex justify-between items-center h-14 min-h-[3.5rem] px-4 py-2 bg-white dark:bg-slate-900 border-b border-slate-50 dark:border-slate-800/50"
  >
    <h1
      class="text-2xl mb-0 flex items-center text-slate-900 dark:text-slate-100"
    >
      <woot-sidemenu-icon v-if="showSidemenuIcon" />
      <back-button
        v-if="showBackButton"
        :button-label="backButtonLabel"
        :back-url="backUrl"
      />
      <fluent-icon
        v-if="icon && !customIcon"
        :icon="icon"
        :class="iconClass"
        class="mr-2 ml-1 rtl:ml-2 rtl:mr-1 hidden md:block"
      />
      <svg
        v-if="customIcon"
        class="mr-2 ml-1 rtl:ml-2 rtl:mr-1 hidden md:block text-slate-710 dark:text-slate-100"
        width="20"
        height="20"
        viewBox="0 0 20 20"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <g clip-path="url(#clip0_1769_4268)">
          <path
            d="M15.625 4.375H4.375C3.33947 4.375 2.5 5.21447 2.5 6.25V15C2.5 16.0355 3.33947 16.875 4.375 16.875H15.625C16.6605 16.875 17.5 16.0355 17.5 15V6.25C17.5 5.21447 16.6605 4.375 15.625 4.375Z"
            stroke="currentColor"
            stroke-width="1.3"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
          <path
            d="M12.8125 11.25H7.1875C6.32456 11.25 5.625 11.9496 5.625 12.8125C5.625 13.6754 6.32456 14.375 7.1875 14.375H12.8125C13.6754 14.375 14.375 13.6754 14.375 12.8125C14.375 11.9496 13.6754 11.25 12.8125 11.25Z"
            stroke="currentColor"
            stroke-width="1.3"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
          <path
            d="M10 4.375V1.25"
            stroke="currentColor"
            stroke-width="1.3"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
          <path
            d="M6.5625 9.375C7.08027 9.375 7.5 8.95527 7.5 8.4375C7.5 7.91973 7.08027 7.5 6.5625 7.5C6.04473 7.5 5.625 7.91973 5.625 8.4375C5.625 8.95527 6.04473 9.375 6.5625 9.375Z"
            fill="currentColor"
          />
          <path
            d="M13.4375 9.375C13.9553 9.375 14.375 8.95527 14.375 8.4375C14.375 7.91973 13.9553 7.5 13.4375 7.5C12.9197 7.5 12.5 7.91973 12.5 8.4375C12.5 8.95527 12.9197 9.375 13.4375 9.375Z"
            fill="currentColor"
          />
        </g>
        <defs>
          <clipPath id="clip0_1769_4268">
            <rect width="20" height="20" fill="white" />
          </clipPath>
        </defs>
      </svg>

      <slot />
      <span class="text-slate-900 font-medium text-2xl dark:text-slate-100">
        {{ headerTitle === 'CALLING_SETTINGS' ? 'Calling' : headerTitle }}
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
import BackButton from '../../../components/widgets/BackButton.vue';
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
    customIcon: {
      default: false,
      type: Boolean,
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
