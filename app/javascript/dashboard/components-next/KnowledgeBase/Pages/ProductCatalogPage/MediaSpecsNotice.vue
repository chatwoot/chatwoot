<template>
  <div>
    <!-- Clickable Notice Banner -->
    <button
      class="w-full flex items-center gap-3 px-4 py-3 bg-n-blue-2 border border-n-blue-6 rounded-lg text-left hover:bg-n-blue-3 transition-colors cursor-pointer"
      @click="openDialog"
    >
      <i class="i-lucide-info w-5 h-5 text-n-blue-11 flex-shrink-0" />
      <div class="flex-1 min-w-0">
        <p class="text-sm font-medium text-n-blue-12">
          {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_SPECS.TITLE') }}
        </p>
        <p class="text-xs text-n-blue-11 mt-0.5">
          {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_SPECS.DESCRIPTION') }}
        </p>
      </div>
      <i class="i-lucide-chevron-right w-4 h-4 text-n-blue-11 flex-shrink-0" />
    </button>

    <!-- Dialog with specifications table -->
    <Dialog
      ref="dialogRef"
      :title="$t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_SPECS.DIALOG_TITLE')"
      :description="$t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_SPECS.DIALOG_DESCRIPTION')"
      :show-confirm-button="false"
      :cancel-button-label="$t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_SPECS.CLOSE')"
      width="xl"
    >
      <!-- Specifications Table -->
      <div class="overflow-hidden rounded-lg border border-n-slate-6">
        <table class="w-full">
          <thead class="bg-n-slate-3">
            <tr>
              <th class="px-4 py-3 text-left text-xs font-semibold text-n-slate-12 uppercase tracking-wider">
                {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_SPECS.TABLE.FILE_TYPE') }}
              </th>
              <th class="px-4 py-3 text-left text-xs font-semibold text-n-slate-12 uppercase tracking-wider">
                {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_SPECS.TABLE.EXTENSIONS') }}
              </th>
              <th class="px-4 py-3 text-left text-xs font-semibold text-n-slate-12 uppercase tracking-wider">
                {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_SPECS.TABLE.MAX_SIZE') }}
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-n-slate-6">
            <tr v-for="spec in mediaSpecs" :key="spec.type" class="bg-n-solid-1">
              <td class="px-4 py-3">
                <div class="flex items-center gap-2">
                  <i :class="[spec.icon, 'w-4 h-4', spec.iconColor]" />
                  <span class="text-sm font-medium text-n-slate-12">{{ spec.label }}</span>
                </div>
              </td>
              <td class="px-4 py-3">
                <div class="flex flex-wrap gap-1">
                  <span
                    v-for="ext in spec.extensions"
                    :key="ext"
                    class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-n-slate-3 text-n-slate-11"
                  >
                    {{ ext }}
                  </span>
                </div>
              </td>
              <td class="px-4 py-3">
                <span class="text-sm text-n-slate-11">{{ spec.maxSize }}</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Note -->
      <div class="flex items-start gap-2 mt-4 p-3 bg-n-amber-2 border border-n-amber-6 rounded-lg">
        <i class="i-lucide-alert-triangle w-4 h-4 text-n-amber-11 flex-shrink-0 mt-0.5" />
        <p class="text-xs text-n-amber-11">
          {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_SPECS.NOTE') }}
        </p>
      </div>
    </Dialog>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const { t } = useI18n();
const dialogRef = ref(null);

const mediaSpecs = computed(() => [
  {
    type: 'IMAGE',
    label: t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_SPECS.TYPES.IMAGE'),
    icon: 'i-lucide-image',
    iconColor: 'text-n-green-11',
    extensions: ['.jpeg', '.jpg', '.png'],
    maxSize: '5 MB'
  },
  {
    type: 'VIDEO',
    label: t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_SPECS.TYPES.VIDEO'),
    icon: 'i-lucide-video',
    iconColor: 'text-n-blue-11',
    extensions: ['.mp4'],
    maxSize: '16 MB'
  },
  {
    type: 'DOCUMENT',
    label: t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_SPECS.TYPES.DOCUMENT'),
    icon: 'i-lucide-file-text',
    iconColor: 'text-n-orange-11',
    extensions: ['.txt', '.xls', '.xlsx', '.doc', '.docx', '.ppt', '.pptx', '.pdf'],
    maxSize: '100 MB'
  },
  {
    type: 'AUDIO',
    label: t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_SPECS.TYPES.AUDIO'),
    icon: 'i-lucide-music',
    iconColor: 'text-n-purple-11',
    extensions: ['.mp3', '.ogg'],
    maxSize: '16 MB'
  }
]);

const openDialog = () => {
  dialogRef.value?.open();
};
</script>
