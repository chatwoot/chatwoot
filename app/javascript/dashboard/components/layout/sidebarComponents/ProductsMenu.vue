<template>
  <transition name="menu-slide">
    <div
      v-if="show"
      v-on-clickaway="onClickAway"
      class="left-16 rtl:left-auto rtl:right-3 bottom-40 w-64 absolute z-30 rounded-md shadow-xl bg-white dark:bg-slate-800 py-2 px-2 border border-slate-25 dark:border-slate-700"
      :class="{ 'block visible': show }"
    >
      <woot-dropdown-menu>
        <woot-dropdown-item>
          <woot-button
            variant="clear"
            color-scheme="secondary"
            @click="openOneHashCal"
          >
            <fluent-icon icon="calendar-ltr" size="18" class="mb-1 mr-2" />
            {{ $t('OneHash Cal') }}
          </woot-button>
        </woot-dropdown-item>
        <woot-dropdown-item>
          <woot-button variant="clear" color-scheme="secondary">
            <fluent-icon icon="people-team" size="18" class="mb-1 mr-2" />
            {{ $t('OneHash CRM') }}
            <span class="text-xs ml-2 text-red-500">Coming soon</span>
          </woot-button>
        </woot-dropdown-item>
        <woot-dropdown-item>
          <woot-button variant="clear" color-scheme="secondary">
            <fluent-icon icon="people-settings" size="18" class="mb-1 mr-2" />
            {{ $t('OneHash ERP') }}
            <span class="text-xs ml-3 text-red-500">Coming soon</span>
          </woot-button>
        </woot-dropdown-item>
      </woot-dropdown-menu>
    </div>
  </transition>
</template>

<script>
import { mixin as clickaway } from 'vue-clickaway';
import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';

export default {
  components: {
    WootDropdownMenu,
    WootDropdownItem,
  },
  mixins: [clickaway],
  props: {
    show: {
      type: Boolean,
      default: false,
    },
  },
  methods: {
    handleProfileSettingClick(e, navigate) {
      this.$emit('close');
      navigate(e);
    },
    onClickAway() {
      if (this.show) this.$emit('close');
    },
    openOneHashCal() {
      window.open(
        window.chatwootConfig.onehashCalUrl,
        '_blank',
        'noopener, noreferrer'
      );
    },
  },
};
</script>
