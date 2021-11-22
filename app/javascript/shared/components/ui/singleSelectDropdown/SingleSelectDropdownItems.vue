<template>
  <div class="dropdown-list--wrap">
    <woot-dropdown-menu>
      <woot-dropdown-item v-for="listValue in listValues" :key="listValue">
        <woot-button
          class="dropdown--list"
          variant="clear"
          :class="{
            active: listValue === selectedItem,
          }"
          @click="() => onClick(listValue)"
        >
          <div class="user-wrap">
            <div class="name-wrap">
              <span
                class="name text-truncate text-block-title"
                :title="listValue"
              >
                {{ listValue }}
              </span>
              <i
                v-if="listValue === selectedItem"
                class="icon ion-checkmark-round"
              />
            </div>
          </div>
        </woot-button>
      </woot-dropdown-item>
    </woot-dropdown-menu>
  </div>
</template>

<script>
export default {
  props: {
    listValues: {
      type: Array,
      default: () => [],
    },
    selectedItem: {
      type: String,
      default: '',
    },
  },
  methods: {
    onClick(listValue) {
      this.$emit('click', listValue);
    },
  },
};
</script>

<style lang="scss" scoped>
.dropdown-list--wrap {
  width: 100%;
  display: flex;
  flex-direction: column;
  max-height: 12rem;
  overflow: scroll;
}

.dropdown--list {
  width: 100%;
  max-height: 12rem;
}

.dropdown--list {
  justify-content: space-between;
  width: 100%;

  &.active {
    background-color: var(--w-50);
    color: var(--w-900);
    font-weight: var(--font-weight-bold);
  }

  &:focus {
    background-color: var(--color-background);
  }
}

.user-wrap {
  display: flex;
  align-items: center;
}

.name-wrap {
  display: flex;
  justify-content: space-between;
  min-width: 0;
  width: 100%;
}

.name {
  line-height: var(--space-normal);
  margin: 0 var(--space-small);
}

.icon {
  margin-left: var(--space-smaller);
}
</style>
