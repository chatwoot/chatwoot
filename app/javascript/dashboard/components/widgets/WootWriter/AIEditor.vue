<template>
  <div style="position: relative;">
    <woot-button
      v-tooltip.top-end="'Compose With AI'"
      icon="wand"
      color-scheme="secondary"
      variant="smooth"
      size="small"
      :title="'AI'"
      @click="toggleDropdown"
    />
    <div
      v-if="showActionsDropdown"
      v-on-clickaway="closeDropdown"
      class="dropdown-pane dropdown-pane--open basic-filter"
    >
      <h3 class="page-sub-title">
        Compose with AI
      </h3>
      <p>
        Lorem ipsum dolor sit amet consectetur adipisicing elit. Ducimus odio
        dolorem laborum mollitia nesciunt corrupti saepe recusandae esse nisi
        earum, dignissimos fugiat nobis voluptatibus rerum quo illum. Atque, rem
        voluptatem!
      </p>
      <h4 class="text-block-title">
        Tone
      </h4>
      <div class="filter__item">
        <select v-model="activeValue" class="status--filter">
          <option v-for="item in items" :key="item.status" :value="item.status">
            {{ item.value }}
          </option>
        </select>
      </div>
      <div class="medium-12 columns">
        <div class="modal-footer justify-content-end w-full buttons">
          <woot-button class="button clear" size="tiny">
            Cancel
          </woot-button>
          <woot-button size="tiny">
            Generate
          </woot-button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import wootConstants from 'dashboard/constants/globals';
import { mapGetters } from 'vuex';
import { mixin as clickaway } from 'vue-clickaway';

export default {
  mixins: [clickaway],
  data() {
    return {
      showActionsDropdown: false,
      chatStatusItems: this.$t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS'),
      chatSortItems: this.$t('CHAT_LIST.CHAT_SORT_FILTER_ITEMS'),
      items: [
        {
          value: 'Professional',
          status: 'Professional',
        },
      ],
      activeValue: 'Professional',
    };
  },
  computed: {
    ...mapGetters({
      chatStatusFilter: 'getChatStatusFilter',
      chatSortFilter: 'getChatSortFilter',
    }),
    chatStatus() {
      return this.chatStatusFilter || wootConstants.STATUS_TYPE.OPEN;
    },
    sortFilter() {
      return this.chatSortFilter || wootConstants.SORT_BY_TYPE.LATEST;
    },
  },
  methods: {
    onTabChange(value) {
      this.$emit('changeFilter', value);
      this.closeDropdown();
    },
    toggleDropdown() {
      this.showActionsDropdown = !this.showActionsDropdown;
    },
    closeDropdown() {
      this.showActionsDropdown = false;
    },
    onChangeFilter(type, value) {
      this.$emit('changeFilter', type, value);
    },
  },
};
</script>
<style lang="scss" scoped>
.basic-filter {
  width: 400px;
  margin-top: var(--space-smaller);
  right: 0;
  left: 0;
  padding: var(--space-normal) var(--space-small);
  bottom: 34px;
  position: absolute;
  span {
    font-size: var(--font-size-small);
    font-weight: var(--font-weight-medium);
  }
  .filter__item {
    justify-content: space-between;
    display: flex;
    align-items: center;

    &:last-child {
      margin-top: var(--space-normal);
    }

    span {
      font-size: var(--font-size-mini);
    }
  }
}
.icon {
  margin-right: var(--space-smaller);
}
.dropdown-icon {
  margin-left: var(--space-smaller);
}

.status--filter {
  background-color: var(--color-background-light);
  border: 1px solid var(--color-border);
  font-size: var(--font-size-mini);
  height: var(--space-medium);
  margin: 0 var(--space-smaller);
  padding: 0 var(--space-medium) 0 var(--space-small);
}

.buttons {
  display: flex;
  justify-content: flex-end;
  margin-top: var(--space-normal);
}
</style>
