<script>
import validations from './helpers/validations';
import FormInput from 'v3/components/Form/Input.vue';
import { reactive } from 'vue';
import { useVuelidate } from '@vuelidate/core';

import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
    FormInput,
  },
  props: {
    onSubmit: {
      type: Function,
      default: () => {},
    },
    submitInProgress: {
      type: Boolean,
      default: false,
    },
    formData: {
      type: Object,
      default: () => {},
    },
    submitButtonText: {
      type: String,
      default: '',
    },
  },
  setup(props) {
    const formData = props.formData || {};
    const {
      description = '',
      name: title = '',
      allow_auto_assign: allowAutoAssign = true,
    } = formData;

    const state = reactive({
      description,
      title,
      allowAutoAssign,
    });

    const rules = validations;
    const v$ = useVuelidate(rules, state);
    return { state, v$ };
  },
  methods: {
    handleSubmit() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }
      this.onSubmit({
        description: this.state.description,
        name: this.state.title,
        allow_auto_assign: this.state.allowAutoAssign,
      });
    },
  },
};
</script>

<template>
  <div class="team-form-card w-full shrink-0">
    <section
      class="rounded-xl border border-outline-variant/5 bg-surface-container-low p-6 shadow-sm"
    >
      <form class="mx-0 grid gap-6" @submit.prevent="handleSubmit">
        <FormInput
          v-model="state.title"
          name="title"
          spacing="compact"
          :label="$t('TEAMS_SETTINGS.FORM.NAME.LABEL')"
          :placeholder="$t('TEAMS_SETTINGS.FORM.NAME.PLACEHOLDER')"
          :has-error="v$.title.$error"
          :error-message="v$.title.$error ? v$.title.$errors[0].$message : ''"
          @blur="v$.title.$touch"
        />
        <FormInput
          v-model="state.description"
          name="description"
          spacing="compact"
          :label="$t('TEAMS_SETTINGS.FORM.DESCRIPTION.LABEL')"
          :placeholder="$t('TEAMS_SETTINGS.FORM.DESCRIPTION.PLACEHOLDER')"
          :has-error="v$.description.$error"
          :error-message="
            v$.description.$error ? v$.description.$errors[0].$message : ''
          "
          @blur="v$.description.$touch"
        />
        <div
          class="flex items-start gap-3 rounded-lg border border-outline-variant/20 bg-surface-container-highest/40 p-4"
        >
          <input
            id="team-form-auto-assign"
            v-model="state.allowAutoAssign"
            type="checkbox"
            class="mt-1 size-4 shrink-0 rounded border-outline-variant/40 bg-surface-container-lowest text-secondary focus:ring-secondary"
            :value="true"
          />
          <label
            for="team-form-auto-assign"
            class="mb-0 cursor-pointer text-sm leading-snug text-on-surface"
          >
            {{ $t('TEAMS_SETTINGS.FORM.AUTO_ASSIGN.LABEL') }}
          </label>
        </div>
        <div
          class="flex w-full flex-row justify-end gap-2 border-t border-outline-variant/15 pt-6"
        >
          <NextButton
            type="submit"
            solid
            teal
            md
            :label="submitButtonText"
            :disabled="v$.title.$invalid || submitInProgress"
            :is-loading="submitInProgress"
            class="w-full font-bold shadow-none hover:shadow-[0_0_20px_rgba(4,190,153,0.35)] sm:w-auto sm:min-w-[10rem] rounded-xl"
          />
        </div>
      </form>
    </section>
  </div>
</template>

<style scoped>
.team-form-card :deep(.space-y-1 > label) {
  @apply text-xs font-semibold uppercase tracking-wider text-on-surface-variant;
}
</style>
