<template>
  <div class="macros-properties-panel">
    <div>
      <woot-input
        :label="$t('MACROS.ADD.FORM.NAME.LABEL')"
        :placeholder="$t('MACROS.ADD.FORM.NAME.PLACEHOLDER')"
        :error="$v.macro.name.$error ? $t('MACROS.ADD.FORM.NAME.ERROR') : null"
        :class="{ error: $v.macro.name.$error }"
        @input="updateName"
      />
    </div>
    <div>
      <p class="title">{{ $t('MACROS.EDITOR.VISIBILITY.LABEL') }}</p>
      <div class="macros-form-radio-group">
        <button
          class="card"
          :class="isActive('global')"
          @click="macro.visibility = 'global'"
        >
          <fluent-icon
            v-if="macro.visibility === 'global'"
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
          @click="macro.visibility = 'personal'"
        >
          <fluent-icon
            v-if="macro.visibility === 'personal'"
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
      <div class="macros-information-panel">
        <fluent-icon icon="info" size="20" />
        <p>
          {{ $t('MACROS.ORDER_INFO') }}
        </p>
      </div>
    </div>
    <div class="macros-submit-btn">
      <woot-button size="expanded" color-scheme="success" @click="saveMacro">
        {{ $t('MACROS.HEADER_BTN_TXT_SAVE') }}
      </woot-button>
    </div>
  </div>
</template>

<script>
export default {
  methods: {
    updateName(event) {
      this.$emit('name', event.target.value);
    },
  },
};
</script>

<style scoped>
.macros-properties-panel {
  padding: var(--space-slab);
  background-color: var(--white);
  height: calc(100vh - 5.6rem);
  display: flex;
  flex-direction: column;
  border-left: 1px solid var(--s-50);
}
</style>
