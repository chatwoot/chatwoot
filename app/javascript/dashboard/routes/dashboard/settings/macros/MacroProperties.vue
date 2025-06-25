<template>
  <div class="macros__properties-panel">
    <div>
      <woot-input
        :value="macroName"
        :label="$t('MACROS.ADD.FORM.NAME.LABEL')"
        :placeholder="$t('MACROS.ADD.FORM.NAME.PLACEHOLDER')"
        :error="$v.macro.name.$error ? $t('MACROS.ADD.FORM.NAME.ERROR') : null"
        :class="{ error: $v.macro.name.$error }"
        @input="onUpdateName($event)"
      />
    </div>
    <div class="macros__form-visibility-container">
      <p class="title">{{ $t('MACROS.EDITOR.VISIBILITY.LABEL') }}</p>
      <div class="macros__form-visibility">
        <button
          class="card"
          :class="isActive('global')"
          @click="onUpdateVisibility('global')"
        >
          <fluent-icon
            v-if="macroVisibility === 'global'"
            icon="checkmark-circle"
            type="solid"
            class="visibility-check"
          />
          <p class="title">
            {{ $t('MACROS.EDITOR.VISIBILITY.GLOBAL.LABEL') }}
          </p>
          <p class="subtitle">
            {{ $t('MACROS.EDITOR.VISIBILITY.GLOBAL.DESCRIPTION') }}
          </p>
        </button>
        <button
          class="card"
          :class="isActive('personal')"
          @click="onUpdateVisibility('personal')"
        >
          <fluent-icon
            v-if="macroVisibility === 'personal'"
            icon="checkmark-circle"
            type="solid"
            class="visibility-check"
          />
          <p class="title">
            {{ $t('MACROS.EDITOR.VISIBILITY.PERSONAL.LABEL') }}
          </p>
          <p class="subtitle">
            {{ $t('MACROS.EDITOR.VISIBILITY.PERSONAL.DESCRIPTION') }}
          </p>
        </button>
      </div>
      <div class="macros__info-panel">
        <fluent-icon icon="info" size="20" />
        <p>
          {{ $t('MACROS.ORDER_INFO') }}
        </p>
      </div>
    </div>
    <div class="macros__submit-button">
      <woot-button
        size="expanded"
        color-scheme="success"
        @click="$emit('submit')"
      >
        {{ $t('MACROS.HEADER_BTN_TXT_SAVE') }}
      </woot-button>
    </div>
  </div>
</template>

<script>
export default {
  inject: ['$v'],
  props: {
    macroName: {
      type: String,
      default: '',
    },
    macroVisibility: {
      type: String,
      default: 'global',
    },
  },
  methods: {
    isActive(key) {
      return { active: this.macroVisibility === key };
    },
    onUpdateName(value) {
      this.$emit('update:name', value);
    },
    onUpdateVisibility(value) {
      this.$emit('update:visibility', value);
    },
  },
};
</script>

<style scoped lang="scss">
.macros__properties-panel {
  padding: var(--space-slab);
  background-color: var(--white);
  // full screen height subtracted by the height of the header
  height: calc(100vh - 5.6rem);
  display: flex;
  flex-direction: column;
  border-left: 1px solid var(--s-50);
}

.macros__submit-button {
  margin-top: auto;
}
.macros__form-visibility-container {
  margin-top: var(--space-small);
}
.macros__form-visibility {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: var(--space-slab);

  .card {
    padding: var(--space-small);
    border-radius: var(--border-radius-normal);
    border: 1px solid var(--s-200);
    text-align: left;
    cursor: pointer;
    position: relative;

    &.active {
      background-color: var(--w-25);
      border: 1px solid var(--w-300);
    }

    .visibility-check {
      position: absolute;
      color: var(--w-500);
      top: var(--space-small);
      right: var(--space-small);
    }
  }
}

.subtitle {
  font-size: var(--font-size-mini);
  color: var(--s-500);
}

.title {
  display: block;
  margin: 0;
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-medium);
  line-height: 1.8;
  color: var(--color-body);
}

.macros__info-panel {
  margin-top: var(--space-small);
  display: flex;
  background-color: var(--s-50);
  padding: var(--space-small);
  border-radius: var(--border-radius-normal);
  align-items: flex-start;
  svg {
    flex-shrink: 0;
  }
  p {
    margin-left: var(--space-small);
    margin-bottom: 0;
    color: var(--s-600);
  }
}

::v-deep input[type='text'] {
  margin-bottom: 0;
}

::v-deep .error {
  .message {
    margin-bottom: 0;
  }
}
</style>
