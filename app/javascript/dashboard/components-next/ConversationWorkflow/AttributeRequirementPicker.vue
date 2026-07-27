<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  attributes: { type: Array, default: () => [] },
  selectedKeys: { type: Array, default: () => [] },
  selectedCategories: { type: Array, default: () => [] },
  emptyLabel: { type: String, default: '' },
});

const emit = defineEmits(['update:selectedKeys', 'update:selectedCategories']);

const { t } = useI18n();

const writableAttributes = computed(() =>
  (props.attributes || []).filter(attr => !attr.formula)
);

const groups = computed(() => {
  const byCategory = new Map();
  writableAttributes.value.forEach(attr => {
    const key = attr.attributeKey || attr.attribute_key;
    const label = attr.attributeDisplayName || attr.attribute_display_name;
    const category =
      (attr.category || '').trim() || t('BUSINESS_RULES.FIELDS.UNCATEGORIZED');
    if (!byCategory.has(category)) byCategory.set(category, []);
    byCategory.get(category).push({ value: key, label });
  });
  return Array.from(byCategory.entries()).map(([category, items]) => ({
    category,
    items,
  }));
});

const keysSet = computed(() => new Set(props.selectedKeys || []));
const categoriesSet = computed(() => new Set(props.selectedCategories || []));

const isKeyChecked = key => keysSet.value.has(key);
const isCategoryChecked = category => categoriesSet.value.has(category);

const categoryState = category => {
  const group = groups.value.find(g => g.category === category);
  if (!group) return 'none';
  if (isCategoryChecked(category)) return 'all';
  const selectedCount = group.items.filter(item =>
    isKeyChecked(item.value)
  ).length;
  if (selectedCount === 0) return 'none';
  return 'partial';
};

const toggleKey = key => {
  const next = new Set(props.selectedKeys || []);
  if (next.has(key)) next.delete(key);
  else next.add(key);
  emit('update:selectedKeys', Array.from(next));
};

const toggleCategory = category => {
  const nextCats = new Set(props.selectedCategories || []);
  const group = groups.value.find(g => g.category === category);
  const nextKeys = new Set(props.selectedKeys || []);
  if (nextCats.has(category)) {
    nextCats.delete(category);
    (group?.items || []).forEach(item => nextKeys.delete(item.value));
  } else {
    nextCats.add(category);
    (group?.items || []).forEach(item => nextKeys.delete(item.value));
  }
  emit('update:selectedCategories', Array.from(nextCats));
  emit('update:selectedKeys', Array.from(nextKeys));
};
</script>

<template>
  <div
    class="flex max-h-56 flex-col gap-3 overflow-y-auto rounded-md border border-n-weak p-2"
  >
    <p v-if="!groups.length" class="m-0 text-xs text-n-slate-11">
      {{ emptyLabel }}
    </p>
    <div
      v-for="group in groups"
      :key="group.category"
      class="flex flex-col gap-1"
    >
      <label
        class="flex items-center gap-2 text-sm font-medium text-n-slate-12"
      >
        <input
          type="checkbox"
          :checked="categoryState(group.category) === 'all'"
          :indeterminate.prop="categoryState(group.category) === 'partial'"
          @change="toggleCategory(group.category)"
        />
        <span>
          {{ group.category }}
          <span class="font-normal text-n-slate-11">
            ({{
              $t('BUSINESS_RULES.FIELDS.CATEGORY_ALL_HELP', {
                count: group.items.length,
              })
            }})
          </span>
        </span>
      </label>
      <label
        v-for="item in group.items"
        :key="item.value"
        class="ml-5 flex items-center gap-2 text-sm text-n-slate-12"
      >
        <input
          type="checkbox"
          :checked="
            isCategoryChecked(group.category) || isKeyChecked(item.value)
          "
          :disabled="isCategoryChecked(group.category)"
          @change="toggleKey(item.value)"
        />
        {{ item.label }}
      </label>
    </div>
  </div>
</template>
