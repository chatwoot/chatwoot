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
    macroDescription: {
      type: String,
      default: '',
    },
    macroAiEnabled: {
      type: Boolean,
      default: false,
    },
  },
  emits: [
    'update:name',
    'update:visibility',
    'update:description',
    'update:aiEnabled',
    'submit',
  ],
  computed: {
    isGlobalMacro() {
      return this.macroVisibility === 'global';
    },
  },
  methods: {
    isActive(key) {
      return this.macroVisibility === key
        ? 'bg-n-blue-2 dark:bg-n-blue-1 border-n-blue-3 dark:border-n-blue-4'
        : 'bg-white dark:bg-n-solid-2 border-n-weak dark:border-n-strong';
    },
    onUpdateName(value) {
      this.$emit('update:name', value);
    },
    onUpdateVisibility(value) {
      this.$emit('update:visibility', value);
      // Reset AI enabled when switching to personal
      if (value === 'personal') {
        this.$emit('update:aiEnabled', false);
      }
    },
    onUpdateDescription(event) {
      this.$emit('update:description', event.target.value);
    },
    onUpdateAiEnabled(event) {
      this.$emit('update:aiEnabled', event.target.checked);
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
    <div class="mt-3">
      <label class="block text-sm font-medium leading-[1.8] text-n-slate-12">
        {{ $t('MACROS.ADD.FORM.DESCRIPTION.LABEL') }}
      </label>
      <textarea
        :value="macroDescription"
        :placeholder="$t('MACROS.ADD.FORM.DESCRIPTION.PLACEHOLDER')"
        class="w-full px-3 py-2 text-sm border rounded-md resize-none bg-white dark:bg-n-solid-3 border-n-weak dark:border-n-strong text-n-slate-12 placeholder:text-n-slate-10 focus:outline-none focus:ring-1 focus:ring-n-brand focus:border-n-brand"
        :class="{ 'border-n-ruby-9': v$.macro.description?.$error }"
        rows="3"
        @input="onUpdateDescription"
      />
      <p v-if="v$.macro.description?.$error" class="mt-1 text-xs text-n-ruby-9">
        {{ $t('MACROS.ADD.FORM.DESCRIPTION.ERROR') }}
      </p>
      <p v-else class="mt-1 text-xs text-n-slate-11">
        {{ $t('MACROS.ADD.FORM.DESCRIPTION.HELP_TEXT') }}
      </p>
    </div>
    <div class="mt-3">
      <p class="block m-0 text-sm font-medium leading-[1.8] text-n-slate-12">
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
            class="absolute text-n-brand top-2 right-2"
          />
          <p
            class="block m-0 text-sm font-medium leading-[1.8] text-n-slate-12"
          >
            {{ $t('MACROS.EDITOR.VISIBILITY.GLOBAL.LABEL') }}
          </p>
          <p class="text-xs text-n-slate-11">
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
            class="absolute text-n-brand top-2 right-2"
          />
          <p
            class="block m-0 text-sm font-medium leading-[1.8] text-n-slate-12"
          >
            {{ $t('MACROS.EDITOR.VISIBILITY.PERSONAL.LABEL') }}
          </p>
          <p class="text-xs text-n-slate-11">
            {{ $t('MACROS.EDITOR.VISIBILITY.PERSONAL.DESCRIPTION') }}
          </p>
        </button>
      </div>
      <div
        class="mt-2 flex items-start p-2 bg-n-slate-3 dark:bg-n-solid-3 rounded-md"
      >
        <fluent-icon icon="info" size="16" class="flex-shrink-0 mt-0.5" />
        <p class="ml-2 rtl:ml-0 rtl:mr-2 mb-0 text-n-slate-11">
          {{ $t('MACROS.ORDER_INFO') }}
        </p>
      </div>
    </div>
    <div v-if="isGlobalMacro" class="mt-3">
      <label class="flex items-center gap-3 cursor-pointer">
        <input
          type="checkbox"
          :checked="macroAiEnabled"
          class="w-4 h-4 rounded border-n-weak text-n-brand focus:ring-n-brand focus:ring-offset-0"
          @change="onUpdateAiEnabled"
        />
        <span class="text-sm font-medium text-n-slate-12">
          {{ $t('MACROS.ADD.FORM.AI_ENABLED.LABEL') }}
        </span>
      </label>
      <p class="mt-1 text-xs text-n-slate-11 ml-7">
        {{ $t('MACROS.ADD.FORM.AI_ENABLED.HELP_TEXT') }}
      </p>
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
