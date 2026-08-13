<script setup>
import { useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'next/button/Button.vue';
import FilterSelect from 'dashboard/components-next/filter/inputs/FilterSelect.vue';
import ConditionRow from 'dashboard/components-next/filter/ConditionRow.vue';

const props = defineProps({
  filterTypes: { type: Array, required: true },
  depth: { type: Number, default: 0 },
  maxDepth: { type: Number, default: 1 },
  isRoot: { type: Boolean, default: false },
});

const emit = defineEmits(['remove']);

const node = defineModel({ type: Object, required: true });

const { t } = useI18n();

let uid = 0;
const nextId = () => {
  uid += 1;
  return `audience-${Date.now()}-${uid}`;
};

const DEFAULT_LEAF = () => ({
  id: nextId(),
  attributeKey: 'email',
  filterOperator: 'contains',
  values: '',
  attributeModel: 'standard',
});

const operatorOptions = [
  { value: 'and', label: t('CAPTAIN.ASSISTANTS.FORM.AUDIENCE.MATCH_ALL') },
  { value: 'or', label: t('CAPTAIN.ASSISTANTS.FORM.AUDIENCE.MATCH_ANY') },
];

const isGroup = child =>
  Object.prototype.hasOwnProperty.call(child, 'conditions');

const addCondition = () => {
  node.value.conditions.push(DEFAULT_LEAF());
};

const addGroup = () => {
  node.value.conditions.push({
    id: nextId(),
    operator: 'and',
    conditions: [DEFAULT_LEAF()],
  });
};

const removeChild = index => {
  node.value.conditions.splice(index, 1);
  // A nested group must always hold at least one condition; remove the whole group when emptied.
  if (!props.isRoot && node.value.conditions.length === 0) {
    emit('remove');
  }
};

const leafRefs = useTemplateRef('leafRefs');
const groupRefs = useTemplateRef('groupRefs');

const validate = () => {
  const leavesValid = (leafRefs.value ?? []).every(row => row.validate());
  const groupsValid = (groupRefs.value ?? []).every(group => group.validate());
  return leavesValid && groupsValid;
};

defineExpose({ validate });
</script>

<template>
  <div
    class="flex flex-col gap-4 group/audience-group"
    :class="
      isRoot
        ? 'p-4 border border-n-weak rounded-xl'
        : 'p-3 border border-n-weak bg-n-alpha-1 rounded-lg'
    "
  >
    <div class="flex items-center gap-2">
      <div class="flex items-center gap-1.5 text-sm text-n-slate-11">
        <span>{{ t('CAPTAIN.ASSISTANTS.FORM.AUDIENCE.MATCH_PREFIX') }}</span>
        <FilterSelect
          v-model="node.operator"
          variant="faded"
          hide-icon
          class="text-sm"
          :options="operatorOptions"
        />
        <span>{{ t('CAPTAIN.ASSISTANTS.FORM.AUDIENCE.MATCH_SUFFIX') }}</span>
      </div>
      <Button
        v-if="!isRoot"
        sm
        ghost
        slate
        icon="i-lucide-trash"
        class="ml-auto flex-shrink-0 opacity-0 transition-opacity group-hover/audience-group:opacity-100"
        @click="emit('remove')"
      />
    </div>

    <ul class="grid gap-3 list-none">
      <template v-for="(child, index) in node.conditions" :key="child.id">
        <AudienceGroup
          v-if="isGroup(child)"
          ref="groupRefs"
          v-model="node.conditions[index]"
          :filter-types="filterTypes"
          :depth="depth + 1"
          :max-depth="maxDepth"
          @remove="removeChild(index)"
        />
        <ConditionRow
          v-else
          ref="leafRefs"
          v-model:attribute-key="child.attributeKey"
          v-model:filter-operator="child.filterOperator"
          v-model:values="child.values"
          :filter-types="filterTypes"
          :show-query-operator="false"
          @remove="removeChild(index)"
        />
      </template>
    </ul>

    <div
      v-if="isRoot && !node.conditions.length"
      class="flex flex-col items-center gap-1.5 px-4 py-8 text-center border border-dashed rounded-lg border-n-strong"
    >
      <span class="text-2xl i-lucide-users-round text-n-slate-10" />
      <p class="text-sm font-medium text-n-slate-12">
        {{ t('CAPTAIN.ASSISTANTS.FORM.AUDIENCE.EMPTY_TITLE') }}
      </p>
      <p class="max-w-md text-sm text-n-slate-11">
        {{ t('CAPTAIN.ASSISTANTS.FORM.AUDIENCE.EMPTY_BODY') }}
      </p>
    </div>

    <div class="flex gap-2">
      <Button
        sm
        ghost
        blue
        icon="i-lucide-plus"
        class="flex-shrink-0"
        :label="t('CAPTAIN.ASSISTANTS.FORM.AUDIENCE.ADD_CONDITION')"
        @click="addCondition"
      />
      <Button
        v-if="depth < maxDepth"
        sm
        ghost
        blue
        icon="i-lucide-plus"
        class="flex-shrink-0"
        :label="t('CAPTAIN.ASSISTANTS.FORM.AUDIENCE.ADD_GROUP')"
        @click="addGroup"
      />
    </div>
  </div>
</template>
