<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import AutoQaAPI from 'dashboard/api/autoQa';
import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const records = ref([]);
const isLoading = ref(true);

const fetchAutoQaRecords = async () => {
  isLoading.value = true;
  try {
    const response = await AutoQaAPI.get();
    records.value = response.data;
  } catch (error) {
    useAlert(t('AUTO_QA.LOADING'));
  } finally {
    isLoading.value = false;
  }
};

onMounted(() => {
  fetchAutoQaRecords();
});
</script>

<template>
  <div class="flex flex-col h-full bg-slate-50 dark:bg-slate-900 p-6">
    <div class="mb-4">
      <h2 class="text-2xl font-semibold text-slate-900 dark:text-white">
        {{ $t('AUTO_QA.HEADER') }}
      </h2>
      <p class="text-slate-600 dark:text-slate-400">
        {{ $t('AUTO_QA.DESCRIPTION') }}
      </p>
    </div>

    <div v-if="isLoading" class="flex items-center justify-center h-64">
      <span class="text-slate-500">{{ $t('AUTO_QA.LOADING') }}</span>
    </div>

    <div
      v-else-if="!records.length"
      class="flex items-center justify-center h-64 border rounded-lg bg-white dark:bg-slate-800 dark:border-slate-700"
    >
      <span class="text-slate-500">
        {{ $t('AUTO_QA.EMPTY') }}
      </span>
    </div>

    <div
      v-else
      class="flex-1 overflow-auto bg-white border rounded-lg shadow-sm dark:bg-slate-800 dark:border-slate-700"
    >
      <table class="w-full text-left border-collapse">
        <thead>
          <tr
            class="bg-slate-50 dark:bg-slate-800/50 border-b dark:border-slate-700"
          >
            <th class="p-4 font-medium text-slate-600 dark:text-slate-300">
              {{ $t('AUTO_QA.TABLE.CONVERSATION_ID') }}
            </th>
            <th class="p-4 font-medium text-slate-600 dark:text-slate-300">
              {{ $t('AUTO_QA.TABLE.AGENT') }}
            </th>
            <th class="p-4 font-medium text-slate-600 dark:text-slate-300">
              {{ $t('AUTO_QA.TABLE.SCORE') }}
            </th>
            <th class="p-4 font-medium text-slate-600 dark:text-slate-300">
              {{ $t('AUTO_QA.TABLE.FEEDBACK') }}
            </th>
            <th
              class="p-4 font-medium text-slate-600 dark:text-slate-300 text-right"
            >
              {{ $t('AUTO_QA.TABLE.ACTION') }}
            </th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="record in records"
            :key="record.id"
            class="border-b dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-700/50"
          >
            <td class="p-4">#{{ record.display_id }}</td>
            <td class="p-4">
              {{
                record.assignee
                  ? record.assignee.name
                  : $t('AUTO_QA.TABLE.UNASSIGNED')
              }}
            </td>
            <td class="p-4">
              <span
                class="px-2 py-1 text-sm rounded-full font-medium"
                :class="{
                  'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400':
                    record.auto_qa_score < 50,
                  'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400':
                    record.auto_qa_score >= 50 && record.auto_qa_score < 80,
                  'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400':
                    record.auto_qa_score >= 80,
                }"
              >
                {{ record.auto_qa_score }}
              </span>
            </td>
            <td class="p-4 max-w-md truncate" :title="record.auto_qa_feedback">
              {{ record.auto_qa_feedback }}
            </td>
            <td class="p-4 text-right">
              <router-link
                :to="`/app/accounts/${$route.params.accountId}/conversations/${record.id}`"
              >
                <Button
                  variant="outline"
                  size="sm"
                  :label="$t('AUTO_QA.TABLE.VIEW')"
                />
              </router-link>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
