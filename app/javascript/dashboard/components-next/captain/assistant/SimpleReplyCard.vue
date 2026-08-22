<script setup>
import { computed, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import TagInput from 'dashboard/components-next/taginput/TagInput.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import CardLayout from 'dashboard/components-next/CardLayout.vue';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  name: {
    type: String,
    required: true,
  },
  keywords: {
    type: Array,
    default: () => [],
  },
  reply: {
    type: String,
    required: true,
  },
  matchType: {
    type: String,
    default: 'contains',
  },
  enabled: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['delete', 'update']);

const { t } = useI18n();

const [isEditing, toggleEditing] = useToggle();

const state = reactive({
  name: '',
  keywords: [],
  reply: '',
  matchType: 'contains',
});

const isTogglingEnabled = ref(false);

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

const matchTypeLabel = computed(() =>
  props.matchType === 'exact'
    ? t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.FORM.MATCH_TYPE.EXACT')
    : t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.FORM.MATCH_TYPE.CONTAINS')
);

const startEdit = () => {
  Object.assign(state, {
    name: props.name,
    keywords: [...props.keywords],
    reply: props.reply,
    matchType: props.matchType,
  });
  toggleEditing(true);
};

const onClickUpdate = () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;
  emit('update', { id: props.id, ...state });
  toggleEditing(false);
};
</script>

<template>
  <CardLayout class="relative [&>div]:!py-4" layout="row">
    <div v-if="!isEditing" class="flex flex-col w-full gap-2">
      <div class="flex items-start justify-between w-full gap-2">
        <div class="flex flex-col items-start gap-1">
          <span class="text-sm text-n-slate-12 font-medium">{{ name }}</span>
          <div class="flex items-center gap-1.5 flex-wrap">
            <span
              v-for="keyword in keywords"
              :key="keyword"
              class="text-xs text-n-slate-11 bg-n-alpha-2 rounded-md px-2 py-0.5"
            >
              {{ keyword }}
            </span>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <Button icon="i-lucide-pen" slate xs ghost @click="startEdit" />
          <span class="w-px h-4 bg-n-weak" />
          <Button
            icon="i-lucide-trash"
            slate
            xs
            ghost
            @click="emit('delete', id)"
          />
        </div>
      </div>

      <p class="text-sm text-n-slate-12 mb-0 break-words whitespace-pre-line">
        {{ reply }}
      </p>

      <div class="flex items-center gap-3 text-xs text-n-slate-11">
        <span>{{ matchTypeLabel }}</span>
        <span class="w-px h-3 bg-n-weak" />
        <button
          type="button"
          class="text-n-blue-11 hover:underline"
          :disabled="isTogglingEnabled"
          @click="
            emit('update', {
              id,
              name,
              keywords: [...keywords],
              reply,
              matchType,
              enabled: !enabled,
            })
          "
        >
          {{
            enabled
              ? t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.LIST.DISABLE')
              : t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.LIST.ENABLE')
          }}
        </button>
        <span class="text-n-slate-11" :class="{ 'text-n-green-11': enabled }">
          {{
            enabled
              ? t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.LIST.ENABLED')
              : t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.LIST.DISABLED')
          }}
        </span>
      </div>
    </div>
    <div v-else class="overflow-hidden flex flex-col gap-4 w-full">
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

      <div class="flex items-center gap-3">
        <Button
          faded
          slate
          sm
          :label="t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.UPDATE.CANCEL')"
          @click="toggleEditing(false)"
        />
        <Button
          sm
          :label="t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.UPDATE.UPDATE')"
          @click="onClickUpdate"
        />
      </div>
    </div>
  </CardLayout>
</template>
