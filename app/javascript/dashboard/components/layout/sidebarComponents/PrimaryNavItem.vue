<script>
import { OnClickOutside } from '@vueuse/components';
import { HELP_CENTER_MENU_ITEMS } from 'dashboard/helper/portalHelper';

import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

export default {
  components: {
    DropdownMenu,
    OnClickOutside,
  },
  props: {
    to: {
      type: String,
      default: '',
    },
    id: {
      type: String,
      default: '',
    },
    name: {
      type: String,
      default: '',
    },
    icon: {
      type: String,
      default: '',
    },
    count: {
      type: String,
      default: '',
    },
    isChildMenuActive: {
      type: Boolean,
      default: false,
    },
    openInNewPage: {
      type: Boolean,
      default: false,
    },
  },

  data() {
    return {
      helpCenterMenu: HELP_CENTER_MENU_ITEMS,
      showHelpCenterMenu: false,
    };
  },
  computed: {
    helpCenterMenuItems() {
      return this.helpCenterMenu.map(item => ({
        ...item,
        isSelected: this.isSelectedMenuItem(item),
      }));
    },
    isHelpCenter() {
      return this.id === 'helpcenter';
    },
    isHelpCenterSelected() {
      const routes = [
        'portals_new',
        'portals_index',
        'portals_articles_index',
        'portals_articles_new',
        'portals_articles_edit',
        'portals_categories_index',
        'portals_categories_articles_index',
        'portals_categories_articles_edit',
        'portals_locales_index',
        'portals_settings_index',
      ];
      return routes.includes(this.$route.name);
    },
  },
  methods: {
    isSelectedMenuItem(menuItem) {
      return menuItem.value.includes(this.$route.name);
    },
    toggleHelpCenterMenu() {
      this.showHelpCenterMenu = !this.showHelpCenterMenu;
    },
    handleHelpCenterAction({ action }) {
      this.$router.push({
        name: 'portals_index',
        params: {
          navigationPath: action,
        },
      });
    },
  },
};
</script>

<template>
  <OnClickOutside v-if="isHelpCenter" @trigger="showHelpCenterMenu = false">
    <button
      v-tooltip.top="$t(`SIDEBAR.${name}`)"
      class="relative flex items-center justify-center w-10 h-10 my-2 rounded-lg text-slate-700 dark:text-slate-100 hover:!bg-slate-25 dark:hover:!bg-slate-700 dark:hover:text-slate-100 hover:text-slate-600"
      :class="{
        'bg-woot-50 dark:bg-slate-800 text-woot-500 hover:bg-woot-50':
          isHelpCenterSelected,
      }"
      @click="toggleHelpCenterMenu"
    >
      <fluent-icon
        :icon="icon"
        :class="{
          'text-woot-500': isHelpCenterSelected,
        }"
      />
      <DropdownMenu
        v-if="showHelpCenterMenu && isHelpCenter"
        :menu-items="helpCenterMenuItems"
        class="ltr:left-10 rtl:right-10 w-36 z-[100] top-0 overflow-y-auto max-h-52"
        @action="handleHelpCenterAction"
      />
    </button>
  </OnClickOutside>

  <router-link v-else v-slot="{ href, isActive, navigate }" :to="to" custom>
    <a
      v-tooltip.right="$t(`SIDEBAR.${name}`)"
      :href="href"
      class="relative flex items-center justify-center w-10 h-10 my-2 rounded-lg text-slate-700 dark:text-slate-100 hover:bg-slate-25 dark:hover:bg-slate-700 dark:hover:text-slate-100 hover:text-slate-600"
      :class="{
        'bg-woot-50 dark:bg-slate-800 text-woot-500 hover:bg-woot-50':
          isActive || isChildMenuActive,
      }"
      :rel="openInNewPage ? 'noopener noreferrer nofollow' : undefined"
      :target="openInNewPage ? '_blank' : undefined"
      @click="navigate"
    >
      <fluent-icon
        :icon="icon"
        :class="{
          'text-woot-500': isActive || isChildMenuActive,
        }"
      />
      <span class="sr-only">{{ name }}</span>
      <span
        v-if="count"
        class="absolute bg-yellow-500 text-black-900 -top-1 -right-1"
      >
        {{ count }}
      </span>
    </a>
  </router-link>
</template>
