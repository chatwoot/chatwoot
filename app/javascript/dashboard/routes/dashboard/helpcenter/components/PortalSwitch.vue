<template>
  <div>
    <woot-dropdown-menu>
      <div class="sticky top-0 dark:bg-slate-800 bg-white">
        <woot-dropdown-item>
          <woot-button
            variant="clear"
            color-scheme="secondary"
            size="small"
            icon="settings"
            @click="$emit('settings')"
          >
            {{ $t('HELP_CENTER.PORTAL.POPOVER.PORTAL_SETTINGS') }}
          </woot-button>
        </woot-dropdown-item>
        <woot-dropdown-item>
          <woot-button
            variant="clear"
            size="small"
            color-scheme="secondary"
            icon="app-folder"
            @click="$emit('all-portals')"
          >
            {{ $t('HELP_CENTER.PORTAL.POPOVER.ALL_PORTALS') }}
          </woot-button>
        </woot-dropdown-item>
      </div>
      <div v-if="portals.length > 1" class="mt-2">
        <woot-dropdown-divider />
        <woot-dropdown-header
          :title="$t('HELP_CENTER.PORTAL.POPOVER.SWITCH_PORTAL')"
        />
        <woot-dropdown-item
          v-for="portal in portals"
          :key="portal.id"
          class="my-1"
        >
          <woot-button
            variant="clear"
            color-scheme="secondary"
            size="small"
            class-name=""
            :is-active="portal.slug === activePortalSlug"
            :is-disabled="portal.slug === activePortalSlug"
            @click="e => onClick(e, portal)"
          >
            <div class="rounded-md relative flex gap-2 -mx-1">
              <thumbnail :username="portal.name" variant="square" size="24px" />

              <div class="flex items-center justify-between">
                <div>
                  <h3
                    class="text-sm leading-4 font-medium text-slate-600 dark:text-slate-100 mb-0"
                  >
                    {{ portal.name }}
                  </h3>
                </div>

                <woot-label
                  v-if="active"
                  size="tiny"
                  color-scheme="success"
                  :title="$t('HELP_CENTER.PORTAL.ACTIVE_BADGE')"
                />
              </div>
            </div>
          </woot-button>
        </woot-dropdown-item>
      </div>
    </woot-dropdown-menu>
  </div>
</template>

<script>
import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';
import WootDropdownDivider from 'shared/components/ui/dropdown/DropdownDivider.vue';
import WootDropdownHeader from 'shared/components/ui/dropdown/DropdownHeader.vue';
import thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import portalMixin from '../mixins/portalMixin';

export default {
  components: {
    thumbnail,
    WootDropdownMenu,
    WootDropdownItem,
    WootDropdownHeader,
    WootDropdownDivider,
  },
  mixins: [portalMixin],
  props: {
    portals: {
      type: Array,
      default: () => [],
    },
    active: {
      type: Boolean,
      default: false,
    },
    activePortalSlug: {
      type: String,
      default: '',
    },
    activeLocale: {
      type: String,
      default: '',
    },
  },
  computed: {},
  methods: {
    onClick(event, portal) {
      const {
        meta: { default_locale: defaultLocale },
      } = portal;
      event.preventDefault();
      this.$emit('switch-portal', {
        portalSlug: portal.slug,
        locale: defaultLocale,
      });
    },
  },
};
</script>

<style lang="scss" scoped>
.dropdown-menu__item {
  @apply mb-0 px-1;
}

.dropdown-menu__item .button {
  @apply px-2 py-1;
}
</style>
