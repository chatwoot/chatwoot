<script>
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  inject: ['v$'],
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
  emits: ['update:name', 'update:visibility', 'submit'],
  methods: {
    isActive(key) {
      return this.macroVisibility === key
        ? 'border-secondary bg-secondary/10 ring-1 ring-secondary/25'
        : 'border-outline-variant/30 bg-surface-container-lowest/80';
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

<template>
  <div
    class="flex h-full flex-col rounded-xl border border-outline-variant/15 bg-surface-container-low p-4 shadow-sm"
  >
    <div>
      <woot-input
        :model-value="macroName"
        :label="$t('MACROS.ADD.FORM.NAME.LABEL')"
        :placeholder="$t('MACROS.ADD.FORM.NAME.PLACEHOLDER')"
        :error="v$.macro.name.$error ? $t('MACROS.ADD.FORM.NAME.ERROR') : null"
        :class="{ error: v$.macro.name.$error }"
        @update:model-value="onUpdateName"
      />
    </div>
    <div class="mt-2">
      <p class="block m-0 text-sm font-medium leading-[1.8] text-on-surface">
        {{ $t('MACROS.EDITOR.VISIBILITY.LABEL') }}
      </p>
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-3">
        <button
          type="button"
          class="relative cursor-pointer rounded-lg border border-solid p-2 text-left transition-colors"
          :class="isActive('global')"
          @click="onUpdateVisibility('global')"
        >
          <fluent-icon
            v-if="macroVisibility === 'global'"
            icon="checkmark-circle"
            type="solid"
            class="absolute right-2 top-2 text-secondary"
          />
          <p
            class="block m-0 text-sm font-medium leading-[1.8] text-on-surface"
          >
            {{ $t('MACROS.EDITOR.VISIBILITY.GLOBAL.LABEL') }}
          </p>
          <p class="text-xs text-on-surface-variant">
            {{ $t('MACROS.EDITOR.VISIBILITY.GLOBAL.DESCRIPTION') }}
          </p>
        </button>
        <button
          type="button"
          class="relative cursor-pointer rounded-lg border border-solid p-2 text-left transition-colors"
          :class="isActive('personal')"
          @click="onUpdateVisibility('personal')"
        >
          <fluent-icon
            v-if="macroVisibility === 'personal'"
            icon="checkmark-circle"
            type="solid"
            class="absolute right-2 top-2 text-secondary"
          />
          <p
            class="block m-0 text-sm font-medium leading-[1.8] text-on-surface"
          >
            {{ $t('MACROS.EDITOR.VISIBILITY.PERSONAL.LABEL') }}
          </p>
          <p class="text-xs text-on-surface-variant">
            {{ $t('MACROS.EDITOR.VISIBILITY.PERSONAL.DESCRIPTION') }}
          </p>
        </button>
      </div>
      <div
        class="mt-2 flex items-start rounded-md bg-surface-container-high/50 p-2"
      >
        <fluent-icon icon="info" size="16" class="mt-0.5 shrink-0" />
        <p class="ml-2 rtl:ml-0 rtl:mr-2 mb-0 text-on-surface-variant">
          {{ $t('MACROS.ORDER_INFO') }}
        </p>
      </div>
    </div>
    <div class="mt-auto w-full border-t border-outline-variant/15 pt-4">
      <NextButton
        solid
        teal
        :label="$t('MACROS.HEADER_BTN_TXT_SAVE')"
        class="w-full rounded-xl font-bold shadow-none hover:shadow-[0_0_20px_rgba(4,190,153,0.35)]"
        @click="$emit('submit')"
      />
    </div>
  </div>
</template>

<style scoped lang="scss">
::v-deep input[type='text'] {
  @apply mb-0;
}

::v-deep .error {
  .message {
    @apply mb-0;
  }
}
</style>
