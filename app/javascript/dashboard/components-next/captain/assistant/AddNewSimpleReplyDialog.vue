<script setup>
import { computed, reactive } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { useVuelidate } from '@vuelidate/core';
import { vOnClickOutside } from '@vueuse/components';
import { required, minLength } from '@vuelidate/validators';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import TagInput from 'dashboard/components-next/taginput/TagInput.vue';
import Select from 'dashboard/components-next/select/Select.vue';

const emit = defineEmits(['add']);

const { t } = useI18n();

const [showPopover, togglePopover] = useToggle();

const state = reactive({
  name: '',
  keywords: [],
  reply: '',
  matchType: 'contains',
});

const rules = {
  name: { required, minLength: minLength(1) },
  keywords: {
    required: value => Array.isArray(value) && value.length > 0,
  },
  reply: { required },
};

const v$ = useVuelidate(rules, state);

const nameError = computed(() =>
  v$.value.name.$error
    ? t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.FORM.NAME.ERROR')
    : ''
);

const keywordsError = computed(() =>
  v$.value.keywords.$error
    ? t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.FORM.KEYWORDS.ERROR')
    : ''
);

const replyError = computed(() =>
  v$.value.reply.$error
    ? t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.FORM.REPLY.ERROR')
    : ''
);

const matchTypeOptions = [
  {
    value: 'contains',
    label: t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.FORM.MATCH_TYPE.CONTAINS'),
  },
  {
    value: 'exact',
    label: t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.FORM.MATCH_TYPE.EXACT'),
  },
];

const resetState = () => {
  Object.assign(state, {
    name: '',
    keywords: [],
    reply: '',
    matchType: 'contains',
  });
};

const onClickAdd = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  await emit('add', { ...state });
  resetState();
  togglePopover(false);
};

const onClickCancel = () => {
  togglePopover(false);
};
</script>

<template>
  <div
    v-on-click-outside="() => togglePopover(false)"
    class="inline-flex relative"
  >
    <Button
      :label="t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.ADD.NEW.CREATE')"
      sm
      slate
      class="flex-shrink-0"
      @click="togglePopover(!showPopover)"
    />

    <div
      v-if="showPopover"
      class="w-[31.25rem] absolute top-10 ltr:left-0 rtl:right-0 bg-n-alpha-3 backdrop-blur-[100px] p-6 rounded-xl border border-n-weak shadow-md flex flex-col gap-6 z-50"
    >
      <h3 class="text-base font-medium text-n-slate-12">
        {{ t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.ADD.NEW.TITLE') }}
      </h3>

      <div class="flex flex-col gap-4">
        <Input
          v-model="state.name"
          :label="t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.FORM.NAME.LABEL')"
          :placeholder="
            t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.FORM.NAME.PLACEHOLDER')
          "
          :message="nameError"
          :message-type="nameError ? 'error' : 'info'"
        />

        <div class="flex flex-col gap-1.5">
          <label class="text-sm text-n-slate-11">
            {{ t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.FORM.KEYWORDS.LABEL') }}
          </label>
          <TagInput
            :model-value="state.keywords"
            :placeholder="
              t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.FORM.KEYWORDS.PLACEHOLDER')
            "
            allow-create
            @update:model-value="value => (state.keywords = value)"
          />
          <span v-if="keywordsError" class="text-xs text-n-ruby-11">
            {{ keywordsError }}
          </span>
        </div>

        <TextArea
          v-model="state.reply"
          :max-length="2000"
          :label="t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.FORM.REPLY.LABEL')"
          :placeholder="
            t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.FORM.REPLY.PLACEHOLDER')
          "
          :message="replyError"
          :message-type="replyError ? 'error' : 'info'"
          show-character-count
        />

        <Select
          v-model="state.matchType"
          :options="matchTypeOptions"
          :label="t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.FORM.MATCH_TYPE.LABEL')"
        />
      </div>

      <div class="flex items-center justify-between w-full gap-3">
        <Button
          variant="faded"
          color="slate"
          :label="t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.FORM.CANCEL')"
          class="w-full bg-n-alpha-2 !text-n-blue-11 hover:bg-n-alpha-3"
          @click="onClickCancel"
        />
        <Button
          :label="t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.FORM.SUBMIT')"
          class="w-full"
          @click="onClickAdd"
        />
      </div>
    </div>
  </div>
</template>
