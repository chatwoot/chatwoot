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

<template>
  <div
    class="p-4 bg-n-solid-2 border border-n-weak rounded-lg shadow-sm h-full flex flex-col"
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
        class="mt-2 flex items-start p-2 bg-n-slate-3 dark:bg-n-solid-3 rounded-md"
      >
        <fluent-icon icon="info" size="16" class="flex-shrink-0 mt-0.5" />
        <p
          class="ml-2 rtl:ml-0 rtl:mr-2 mb-0 text-slate-600 dark:text-slate-200"
        >
          {{ $t('MACROS.ORDER_INFO') }}
        </p>
      </div>
    </div>
    <div class="mt-auto w-full">
      <NextButton
        blue
        solid
        :label="$t('MACROS.HEADER_BTN_TXT_SAVE')"
        class="w-full"
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
