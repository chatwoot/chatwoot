<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Textarea from 'dashboard/components-next/textarea/Textarea.vue';

const props = defineProps({
  resource: { type: Object, default: () => ({}) },
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['save', 'cancel']);

const { t } = useI18n();

const form = ref({
  title: '',
  description: '',
  content: '',
  custom_attributes: {},
});

// Watch for changes in resource prop and update form
watch(
  () => props.resource,
  newResource => {
    if (newResource) {
      form.value = {
        title: newResource.title || '',
        description: newResource.description || '',
        content: newResource.content || '',
        custom_attributes: newResource.custom_attributes || {},
      };
    }
  },
  { immediate: true }
);

const isValid = computed(() => {
  return (
    form.value.title.trim() &&
    form.value.description.trim() &&
    form.value.content.trim()
  );
});

// Custom attributes management
const customAttributes = ref([]);

// Initialize custom attributes from form data only once
watch(
  () => props.resource,
  newResource => {
    if (newResource && newResource.custom_attributes) {
      customAttributes.value = Object.entries(
        newResource.custom_attributes
      ).map(([key, value]) => ({
        key,
        label: key.charAt(0).toUpperCase() + key.slice(1),
        value,
      }));
    }
  },
  { immediate: true }
);

const addCustomAttribute = () => {
  customAttributes.value.push({ key: '', label: '', value: '' });
};

const updateCustomAttributesForm = () => {
  const attrs = {};
  customAttributes.value.forEach(attr => {
    if (attr.key && attr.value) {
      attrs[attr.key] = attr.value;
    }
  });
  form.value.custom_attributes = attrs;
};

const removeCustomAttribute = index => {
  customAttributes.value.splice(index, 1);
  updateCustomAttributesForm();
};

const handleSave = () => {
  if (isValid.value) {
    // Ensure custom attributes are up to date before saving
    updateCustomAttributesForm();
    emit('save', { ...form.value });
  }
};

const handleCancel = () => {
  emit('cancel');
};
</script>

<template>
  <div class="flex flex-col gap-6 p-6">
    <div class="flex items-center justify-between">
      <h2 class="text-xl font-semibold text-n-base">
        {{
          resource?.id
            ? t('LIBRARY.FORM.EDIT_TITLE')
            : t('LIBRARY.FORM.ADD_TITLE')
        }}
      </h2>
    </div>

    <form class="flex flex-col gap-4" @submit.prevent="handleSave">
      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('LIBRARY.FORM.TITLE_LABEL') }}
        </label>
        <Input
          v-model="form.title"
          :placeholder="t('LIBRARY.FORM.TITLE_PLACEHOLDER')"
          required
        />
      </div>

      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('LIBRARY.FORM.DESCRIPTION_LABEL') }}
        </label>
        <Textarea
          v-model="form.description"
          :placeholder="t('LIBRARY.FORM.DESCRIPTION_PLACEHOLDER')"
          rows="3"
          required
        />
      </div>

      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('LIBRARY.FORM.CONTENT_LABEL') }}
        </label>
        <Textarea
          v-model="form.content"
          :placeholder="t('LIBRARY.FORM.CONTENT_PLACEHOLDER')"
          rows="10"
          required
        />
      </div>

      <!-- Custom Attributes Section -->
      <div>
        <div class="flex items-center justify-between mb-3">
          <label class="block text-sm font-medium text-n-slate-12">
            {{ t('LIBRARY.FORM.CUSTOM_ATTRIBUTES_LABEL') }}
          </label>
          <Button
            variant="outline"
            size="sm"
            type="button"
            @click="addCustomAttribute"
          >
            {{ t('LIBRARY.FORM.CUSTOM_ATTRIBUTES_ADD') }}
          </Button>
        </div>

        <div
          v-if="customAttributes.length === 0"
          class="text-sm text-n-slate-10 italic"
        >
          {{ t('LIBRARY.FORM.CUSTOM_ATTRIBUTES_EMPTY') }}
        </div>

        <div v-else class="space-y-3">
          <div
            v-for="(attr, index) in customAttributes"
            :key="index"
            class="flex gap-3 items-start p-3 border border-n-weak rounded-md"
          >
            <div class="flex-1">
              <Input
                v-model="attr.key"
                :placeholder="
                  t('LIBRARY.FORM.CUSTOM_ATTRIBUTES_KEY_PLACEHOLDER')
                "
                class="mb-2"
                @blur="updateCustomAttributesForm"
              />
              <Input
                v-model="attr.label"
                :placeholder="
                  t('LIBRARY.FORM.CUSTOM_ATTRIBUTES_LABEL_PLACEHOLDER')
                "
                class="mb-2"
              />
              <Input
                v-model="attr.value"
                :placeholder="
                  t('LIBRARY.FORM.CUSTOM_ATTRIBUTES_VALUE_PLACEHOLDER')
                "
                @blur="updateCustomAttributesForm"
              />
            </div>
            <Button
              variant="outline"
              size="sm"
              type="button"
              @click="removeCustomAttribute(index)"
            >
              {{ t('LIBRARY.FORM.CUSTOM_ATTRIBUTES_REMOVE') }}
            </Button>
          </div>
        </div>
      </div>

      <div class="flex justify-end gap-3 pt-4 border-t border-n-weak">
        <Button variant="outline" :disabled="isLoading" @click="handleCancel">
          {{ t('LIBRARY.FORM.CANCEL') }}
        </Button>
        <Button
          type="submit"
          :disabled="!isValid || isLoading"
          :loading="isLoading"
        >
          {{ resource?.id ? t('LIBRARY.FORM.UPDATE') : t('LIBRARY.FORM.SAVE') }}
        </Button>
      </div>
    </form>
  </div>
</template>
