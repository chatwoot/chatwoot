<script>
export default {
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
        ? ' !border-n-brand'
        : ' !border-n-strong';
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
    class="px-6 py-5 bg-n-solid-2 outline-1 outline outline-n-container rounded-xl flex flex-col gap-3 text-n-slate-11"
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
      <p class="block m-0 text-sm font-medium text-n-slate-12 mb-2">
        {{ $t('MACROS.EDITOR.VISIBILITY.LABEL') }}
      </p>
      <div class="grid gap-3 pb-4">
        <button
          class="p-4 relative rounded-md border text-left cursor-default bg-n-alpha-3"
          :class="isActive('global')"
          @click="onUpdateVisibility('global')"
        >
          <fluent-icon
            v-if="macroVisibility === 'global'"
            icon="checkmark-circle"
            type="solid"
            class="absolute text-n-brand top-2 right-2"
          />
          <p class="block m-0 text-sm text-n-slate-12 font-medium mb-1">
            {{ $t('MACROS.EDITOR.VISIBILITY.GLOBAL.LABEL') }}
          </p>
          <p class="text-sm text-n-slate-11 mb-0">
            {{ $t('MACROS.EDITOR.VISIBILITY.GLOBAL.DESCRIPTION') }}
          </p>
        </button>
        <button
          class="p-4 relative rounded-md border text-left cursor-default bg-n-alpha-3"
          :class="isActive('personal')"
          @click="onUpdateVisibility('personal')"
        >
          <fluent-icon
            v-if="macroVisibility === 'personal'"
            icon="checkmark-circle"
            type="solid"
            class="absolute text-n-brand top-2 right-2"
          />
          <p class="block m-0 text-sm text-n-slate-12 font-medium mb-1">
            {{ $t('MACROS.EDITOR.VISIBILITY.PERSONAL.LABEL') }}
          </p>
          <p class="text-sm text-n-slate-11 mb-0">
            {{ $t('MACROS.EDITOR.VISIBILITY.PERSONAL.DESCRIPTION') }}
          </p>
        </button>
      </div>
      <div class="mt-2 flex items-start border-t border-n-weak pt-4">
        <p class="text-n-slate-11">
          {{ $t('MACROS.ORDER_INFO') }}
        </p>
      </div>
    </div>
    <div class="mt-auto w-full">
      <woot-button
        size="expanded"
        color-scheme="success"
        class="w-full"
        @click="$emit('submit')"
      >
        {{ $t('MACROS.HEADER_BTN_TXT_SAVE') }}
      </woot-button>
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
