<script setup>
import { computed, watch, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';

const props = defineProps({
  contactId: {
    type: [String, Number],
    required: true,
  },
});

const store = useStore();
const { t } = useI18n();
const route = useRoute();

const allLabels = useMapGetter('labels/getLabels');
const contactLabels = useMapGetter('contactLabels/getContactLabels');

const savedLabels = computed(() => {
  const availableContactLabels = contactLabels.value(props.contactId);
  return allLabels.value.filter(({ title }) =>
    availableContactLabels.includes(title)
  );
});

const fetchLabels = async contactId => {
  if (!contactId) {
    return;
  }
  store.dispatch('contactLabels/get', contactId);
};

watch(
  () => props.contactId,
  (newVal, oldVal) => {
    if (newVal !== oldVal) {
      fetchLabels(newVal);
    }
  }
);
onMounted(() => {
  if (route.params.contactId) {
    fetchLabels(route.params.contactId);
  }
});
</script>

<template>
  <div class="flex flex-wrap items-center gap-2">
    <div
      v-for="label in savedLabels"
      :key="label.id"
      class="bg-n-alpha-2 rounded-md flex items-center h-7 w-fit py-1 ltr:pl-1 rtl:pr-1 ltr:pr-1.5 rtl:pl-1.5"
    >
      <div
        class="w-2 h-2 m-1 rounded-sm"
        :style="{ backgroundColor: label.color }"
      />
      <span class="text-sm text-n-slate-12">
        {{ label.title }}
      </span>
    </div>
    <button
      class="flex items-center gap-1 px-2 py-1 rounded-md outline-dashed h-[26px] outline-1 outline-n-slate-6 hover:bg-n-alpha-2"
    >
      <span class="i-lucide-plus" />
      <span class="text-sm text-n-slate-11">
        {{ t('CONTACTS_LAYOUT.DETAILS.TAG_BUTTON') }}
      </span>
    </button>
  </div>
</template>
