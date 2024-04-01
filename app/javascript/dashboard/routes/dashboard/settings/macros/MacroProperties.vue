<template>
  <div
    class="p-3 bg-white dark:bg-slate-900 h-[calc(100vh-3.5rem)] flex flex-col border-l border-slate-50 dark:border-slate-800/50"
  >
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
    <div class="mt-2">
      <p
        class="block m-0 text-sm font-medium leading-[1.8] text-slate-700 dark:text-slate-100"
      >
        {{ $t('MACROS.EDITOR.VISIBILITY.LABEL') }}
      </p>
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-3">
        <button
          class="p-2 relative rounded-md border border-solid text-left cursor-default"
          :class="isActive('global')"
          @click="onUpdateVisibility('global')"
        >
          <fluent-icon
            v-if="macroVisibility === 'global'"
            icon="checkmark-circle"
            type="solid"
            class="absolute text-woot-500 dark:text-woot-500 top-2 right-2"
          />
          <p
            class="block m-0 text-sm font-medium leading-[1.8] text-slate-700 dark:text-slate-100"
          >
            {{ $t('MACROS.EDITOR.VISIBILITY.GLOBAL.LABEL') }}
          </p>
          <p class="text-xs text-slate-500 dark:text-slate-200">
            {{ $t('MACROS.EDITOR.VISIBILITY.GLOBAL.DESCRIPTION') }}
          </p>
        </button>
        <button
          class="p-2 relative rounded-md border border-solid text-left cursor-default"
          :class="isActive('personal')"
          @click="onUpdateVisibility('personal')"
        >
          <fluent-icon
            v-if="macroVisibility === 'personal'"
            icon="checkmark-circle"
            type="solid"
            class="absolute text-woot-500 dark:text-woot-500 top-2 right-2"
          />
          <p
            class="block m-0 text-sm font-medium leading-[1.8] text-slate-700 dark:text-slate-100"
          >
            {{ $t('MACROS.EDITOR.VISIBILITY.PERSONAL.LABEL') }}
          </p>
          <p class="text-xs text-slate-500 dark:text-slate-200">
            {{ $t('MACROS.EDITOR.VISIBILITY.PERSONAL.DESCRIPTION') }}
          </p>
        </button>
      </div>
      <div
        class="mt-2 flex items-start p-2 bg-slate-50 dark:bg-slate-700 p-2 rounded-md"
      >
        <fluent-icon icon="info" size="20" class="flex-shrink" />
        <p
          class="ml-2 rtl:ml-0 rtl:mr-2 mb-0 text-slate-600 dark:text-slate-200"
        >
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
      return this.macroVisibility === key
        ? 'bg-woot-25 dark:bg-slate-900 border-woot-200 dark:border-woot-700'
        : 'bg-white dark:bg-slate-900 border-slate-200 dark:border-slate-600';
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
::v-deep input[type='text'] {
  @apply mb-0;
}

::v-deep .error {
  .message {
    @apply mb-0;
  }
}
</style>
