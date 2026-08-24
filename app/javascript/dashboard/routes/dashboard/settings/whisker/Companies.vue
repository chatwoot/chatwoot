<script setup>
import { ref, onMounted, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';
import CompaniesAPI from 'dashboard/api/companies';

const { t } = useI18n();
const companies = ref([]);
const isLoading = ref(false);
const isSubmitting = ref(false);
const showForm = ref(false);
const editing = ref(null);
const form = ref(emptyForm());

function emptyForm() {
  return { name: '', email: '', phone: '', website: '', description: '' };
}

const isEdit = computed(() => !!editing.value);

const load = async () => {
  try {
    isLoading.value = true;
    const { data } = await CompaniesAPI.get();
    companies.value = data;
  } catch (e) {
    useAlert(t('CRM.COMPANIES.API.ERROR'));
  } finally {
    isLoading.value = false;
  }
};

const openCreate = () => {
  editing.value = null;
  form.value = emptyForm();
  showForm.value = true;
};

const openEdit = company => {
  editing.value = company.id;
  form.value = {
    name: company.name,
    email: company.email || '',
    phone: company.phone || '',
    website: company.website || '',
    description: company.description || '',
  };
  showForm.value = true;
};

const save = async () => {
  if (!form.value.name) {
    useAlert(t('CRM.COMPANIES.FORM.NAME_REQUIRED'));
    return;
  }
  try {
    isSubmitting.value = true;
    if (isEdit.value) {
      await CompaniesAPI.update(editing.value, form.value);
    } else {
      await CompaniesAPI.create(form.value);
    }
    showForm.value = false;
    await load();
  } catch (e) {
    useAlert(t('CRM.COMPANIES.API.ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};

const remove = async id => {
  if (!window.confirm(t('CRM.COMPANIES.CONFIRM_DELETE'))) return;
  try {
    await CompaniesAPI.delete(id);
    await load();
  } catch (e) {
    useAlert(t('CRM.COMPANIES.API.ERROR'));
  }
};

onMounted(load);
</script>

<template>
  <div class="flex flex-col w-full outline-1 outline outline-n-container rounded-xl bg-n-solid-2 divide-y divide-n-weak">
    <div class="flex justify-between items-center px-5 py-4">
      <div>
        <h3 class="text-heading-2 text-n-slate-12">{{ t('CRM.COMPANIES.TITLE') }}</h3>
        <p class="mb-0 text-body-para text-n-slate-11">{{ t('CRM.COMPANIES.NOTE') }}</p>
      </div>
      <NextButton blue :label="t('CRM.COMPANIES.NEW')" @click="openCreate" />
    </div>

    <div class="p-5">
      <div v-if="isLoading" class="text-n-slate-11">{{ t('CRM.COMPANIES.LOADING') }}</div>
      <div v-else-if="!companies.length" class="text-n-slate-11">{{ t('CRM.COMPANIES.EMPTY') }}</div>
      <table v-else class="w-full text-sm">
        <thead>
          <tr class="text-left text-n-slate-11">
            <th class="py-2">{{ t('CRM.COMPANIES.FORM.NAME') }}</th>
            <th class="py-2">{{ t('CRM.COMPANIES.FORM.EMAIL') }}</th>
            <th class="py-2">{{ t('CRM.COMPANIES.FORM.PHONE') }}</th>
            <th class="py-2"></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="c in companies" :key="c.id" class="border-t border-n-weak">
            <td class="py-2 font-medium text-n-slate-12">{{ c.name }}</td>
            <td class="py-2">{{ c.email }}</td>
            <td class="py-2">{{ c.phone }}</td>
            <td class="py-2 text-right whitespace-nowrap">
              <button class="text-n-slate-11 hover:text-n-slate-12 mr-3" @click="openEdit(c)">{{ t('CRM.COMPANIES.EDIT') }}</button>
              <button class="text-red-500 hover:text-red-600" @click="remove(c.id)">{{ t('CRM.COMPANIES.DELETE') }}</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="showForm" class="p-5 border-t border-n-weak">
      <form class="grid gap-4" @submit.prevent="save">
        <input v-model="form.name" :placeholder="t('CRM.COMPANIES.FORM.NAME')" class="w-full px-2 py-1.5 rounded-md border border-n-weak bg-n-solid-1" />
        <input v-model="form.email" :placeholder="t('CRM.COMPANIES.FORM.EMAIL')" class="w-full px-2 py-1.5 rounded-md border border-n-weak bg-n-solid-1" />
        <input v-model="form.phone" :placeholder="t('CRM.COMPANIES.FORM.PHONE')" class="w-full px-2 py-1.5 rounded-md border border-n-weak bg-n-solid-1" />
        <input v-model="form.website" :placeholder="t('CRM.COMPANIES.FORM.WEBSITE')" class="w-full px-2 py-1.5 rounded-md border border-n-weak bg-n-solid-1" />
        <textarea v-model="form.description" :placeholder="t('CRM.COMPANIES.FORM.DESCRIPTION')" class="w-full px-2 py-1.5 rounded-md border border-n-weak bg-n-solid-1" rows="3"></textarea>
        <div class="flex gap-2">
          <NextButton blue type="submit" :is-loading="isSubmitting" :label="isEdit ? t('CRM.COMPANIES.SAVE') : t('CRM.COMPANIES.CREATE')" />
          <NextButton @click="showForm = false" :label="t('CRM.COMPANIES.CANCEL')" />
        </div>
      </form>
    </div>
  </div>
</template>
