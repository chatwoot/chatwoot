<template>
  <div v-on-clickaway="onCloseDropdown" class="dropdown-wrap">
    <button :v-model="value" class="button-input" @click="toggleDropdown">
      <Thumbnail
        v-if="value && value.name && value && value.id"
        :src="value && value.thumbnail"
        size="24px"
        :status="value && value.availability_status"
        :badge="value && value.channel"
        :username="value && value.name"
      />
      <div class="name-icon-wrap">
        <div v-if="!noValue" class="name select">
          {{ $t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER') }}
        </div>
        <div v-else class="name" :title="value.name">
          {{ value.name }}
        </div>
        <i v-if="showSearchDropdown" class="icon ion-chevron-up" />
        <i v-else class="icon ion-chevron-down" />
      </div>
    </button>
    <div
      :class="{ 'dropdown-pane--open': showSearchDropdown }"
      class="dropdown-pane"
    >
      <h4 class="text-block-title">
        {{ $t('AGENT_MGMT.MULTI_SELECTOR.TITLE') }}
      </h4>
      <multiselect-dropdown-items
        v-if="showSearchDropdown"
        :options="options"
        :value="value"
        @click="showList"
      />
    </div>
  </div>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import MultiselectDropdownItems from 'shared/components/ui/MultiselectDropdownItems';
import { mixin as clickaway } from 'vue-clickaway';
export default {
  components: {
    Thumbnail,
    MultiselectDropdownItems,
  },

  mixins: [clickaway],

  props: {
    options: {
      type: Array,
      default: () => [],
    },
    value: {
      type: Object,
      default: () => ({}),
    },
  },

  data() {
    return {
      showSearchDropdown: false,
    };
  },

  computed: {
    noValue() {
      if (this.value && this.value.id) {
        return true;
      }
      return false;
    },
  },

  methods: {
    toggleDropdown() {
      this.showSearchDropdown = !this.showSearchDropdown;
    },

    onCloseDropdown() {
      this.showSearchDropdown = false;
    },

    showList(value) {
      this.$emit('click', value);
    },
  },
};
</script>

<style lang="scss" scoped>
.dropdown-wrap {
  display: flex;
  position: relative;
  width: 100%;
  margin-right: var(--space-one);
  margin-bottom: var(--space-small);

  .button-input {
    display: flex;
    width: 100%;
    cursor: pointer;
    justify-content: flex-start;
    background: var(--white);
    font-size: var(--font-size-small);
    border: 1px solid var(--color-border);
    border-radius: var(--border-radius-normal);
    padding: var(--space-small);
  }

  &::v-deep .user-thumbnail-box {
    margin-right: var(--space-one);
  }

  .name-icon-wrap {
    display: flex;
    justify-content: space-between;
    width: 100%;
    padding: var(--space-smaller) 0;
    line-height: var(--space-normal);
    min-width: 0;

    .select {
      color: var(--b-600);
    }

    .name {
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
      margin-right: var(--space-small);
    }
  }

  .dropdown-pane {
    box-sizing: border-box;
    top: 4rem;
    right: 0;
    position: absolute;
    width: 100%;

    &::v-deep {
      .dropdown-menu__item .button {
        width: 100%;
        text-overflow: ellipsis;
        overflow: hidden;
        white-space: nowrap;
        padding: var(--space-smaller) var(--space-small);

        .name-icon-wrap {
          width: 100%;
        }

        .name {
          width: 100%;
        }
      }
    }
  }
}
</style>
