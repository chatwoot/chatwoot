<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import LocationsAPI from 'dashboard/api/locations';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  locationId: { type: Number, default: null },
});

const { t } = useI18n();
const store = useStore();
const router = useRouter();

const isEditMode = computed(() => !!props.locationId);
const isSubmitting = ref(false);
const isLoading = ref(false);

// Form fields
const name = ref('');
const description = ref('');
const typeName = ref('');
const parentLocationId = ref(null);
const hasAddress = ref(false);

// Address fields
const addressId = ref(null);
const street = ref('');
const exteriorNumber = ref('');
const interiorNumber = ref('');
const neighborhood = ref('');
const postalCode = ref('');
const city = ref('');
const state = ref('');
const email = ref('');
const phone = ref('');
const webpage = ref('');
const establishmentSummary = ref('');

const availableParentLocations = computed(() => {
  const allLocations = store.state.locations.records || [];

  if (!isEditMode.value) {
    return allLocations;
  }

  // Exclude current location to prevent being its own parent
  return allLocations.filter(loc => loc.id !== props.locationId);
});

const parentLocationOptions = computed(() => {
  const buildOptions = (locations, level = 0) => {
    const roots = locations.filter(loc => !loc.parent_location_id);
    const options = [];

    roots.forEach(loc => {
      const indent = '\u00A0\u00A0'.repeat(level);
      options.push({
        value: loc.id,
        label: `${indent}${loc.name}`,
      });

      const children = locations.filter(
        child => child.parent_location_id === loc.id
      );
      if (children.length > 0) {
        options.push(...buildChildOptions(children, locations, level + 1));
      }
    });

    return options;
  };

  const buildChildOptions = (children, allLocations, level) => {
    const options = [];
    children.forEach(child => {
      const indent = '\u00A0\u00A0'.repeat(level);
      options.push({
        value: child.id,
        label: `${indent}${child.name}`,
      });

      const grandchildren = allLocations.filter(
        gc => gc.parent_location_id === child.id
      );
      if (grandchildren.length > 0) {
        options.push(...buildChildOptions(grandchildren, allLocations, level + 1));
      }
    });
    return options;
  };

  return [
    { value: null, label: t('LOCATIONS.FORM.NO_PARENT') },
    ...buildOptions(availableParentLocations.value),
  ];
});

const hasRequiredFields = computed(() => {
  return name.value.trim() !== '';
});

const hasRequiredAddressFields = computed(() => {
  if (!hasAddress.value) return true;

  return (
    street.value &&
    exteriorNumber.value &&
    neighborhood.value &&
    postalCode.value &&
    city.value &&
    state.value
  );
});

const loadLocation = async () => {
  if (!props.locationId) return;

  try {
    isLoading.value = true;
    const response = await LocationsAPI.show(props.locationId);
    const location = response.data;

    name.value = location.name || '';
    description.value = location.description || '';
    typeName.value = location.type_name || '';
    parentLocationId.value = location.parent_location_id;

    if (location.address) {
      hasAddress.value = true;
      addressId.value = location.address.id;
      street.value = location.address.street || '';
      exteriorNumber.value = location.address.exterior_number || '';
      interiorNumber.value = location.address.interior_number || '';
      neighborhood.value = location.address.neighborhood || '';
      postalCode.value = location.address.postal_code || '';
      city.value = location.address.city || '';
      state.value = location.address.state || '';
      email.value = location.address.email || '';
      phone.value = location.address.phone || '';
      webpage.value = location.address.webpage || '';
      establishmentSummary.value =
        location.address.establishment_summary || '';
    }
  } catch (error) {
    useAlert(t('LOCATIONS.FORM.LOAD_ERROR'));
    router.push({ name: 'locations_index' });
  } finally {
    isLoading.value = false;
  }
};

const handleSubmit = async () => {
  if (!hasRequiredFields.value) {
    useAlert(t('LOCATIONS.FORM.NAME_REQUIRED'));
    return;
  }

  if (!hasRequiredAddressFields.value) {
    useAlert(t('LOCATIONS.FORM.ADDRESS_INCOMPLETE'));
    return;
  }

  try {
    isSubmitting.value = true;

    const payload = {
      location: {
        name: name.value,
        description: description.value,
        type_name: typeName.value,
        parent_location_id: parentLocationId.value,
      },
    };

    if (hasAddress.value) {
      payload.location.address_attributes = {
        id: addressId.value,
        street: street.value,
        exterior_number: exteriorNumber.value,
        interior_number: interiorNumber.value,
        neighborhood: neighborhood.value,
        postal_code: postalCode.value,
        city: city.value,
        state: state.value,
        email: email.value,
        phone: phone.value,
        webpage: webpage.value,
        establishment_summary: establishmentSummary.value,
      };
    } else if (addressId.value) {
      payload.location.address_attributes = {
        id: addressId.value,
        _destroy: true,
      };
    }

    if (isEditMode.value) {
      await store.dispatch('locations/update', {
        id: props.locationId,
        ...payload.location,
      });
      useAlert(t('LOCATIONS.FORM.UPDATE_SUCCESS'));
    } else {
      await store.dispatch('locations/create', payload.location);
      useAlert(t('LOCATIONS.FORM.CREATE_SUCCESS'));
    }

    router.push({ name: 'locations_index' });
  } catch (error) {
    const errorMessage =
      error?.response?.data?.errors?.join(', ') ||
      t('LOCATIONS.FORM.SUBMIT_ERROR');
    useAlert(errorMessage);
  } finally {
    isSubmitting.value = false;
  }
};

const handleCancel = () => {
  router.push({ name: 'locations_index' });
};

watch(hasAddress, newValue => {
  if (!newValue && !isEditMode.value) {
    street.value = '';
    exteriorNumber.value = '';
    interiorNumber.value = '';
    neighborhood.value = '';
    postalCode.value = '';
    city.value = '';
    state.value = '';
    email.value = '';
    phone.value = '';
    webpage.value = '';
    establishmentSummary.value = '';
  }
});

onMounted(async () => {
  await store.dispatch('locations/get', { page: 1, sortAttr: 'name' });

  if (isEditMode.value) {
    await loadLocation();
  }
});
</script>

<template>
  <div class="flex flex-col h-full bg-n-background">
    <div class="p-6 border-b border-n-weak">
      <h1 class="text-2xl font-semibold text-n-slate-12">
        {{
          isEditMode
            ? t('LOCATIONS.FORM.EDIT_TITLE')
            : t('LOCATIONS.FORM.CREATE_TITLE')
        }}
      </h1>
    </div>

    <div v-if="isLoading" class="flex items-center justify-center flex-1 py-10">
      <Spinner />
    </div>

    <form
      v-else
      class="flex-1 p-6 overflow-y-auto"
      @submit.prevent="handleSubmit"
    >
      <div class="max-w-3xl mx-auto space-y-6">
        <div class="p-6 bg-white border rounded-lg border-n-weak">
          <h2 class="mb-4 text-lg font-semibold text-n-slate-12">
            {{ t('LOCATIONS.FORM.BASIC_INFO') }}
          </h2>

          <div class="space-y-4">
            <div>
              <label class="block mb-1 text-sm font-medium text-n-slate-12">
                {{ t('LOCATIONS.FORM.NAME') }} *
              </label>
              <input
                v-model="name"
                type="text"
                class="w-full px-3 py-2 border rounded-lg border-n-weak bg-white text-n-slate-12 focus:ring-2 focus:ring-n-blue-9"
                :placeholder="t('LOCATIONS.FORM.NAME_PLACEHOLDER')"
                required
              />
            </div>

            <div>
              <label class="block mb-1 text-sm font-medium text-n-slate-12">
                {{ t('LOCATIONS.FORM.TYPE_NAME') }}
              </label>
              <input
                v-model="typeName"
                type="text"
                class="w-full px-3 py-2 border rounded-lg border-n-weak bg-white text-n-slate-12 focus:ring-2 focus:ring-n-blue-9"
                :placeholder="t('LOCATIONS.FORM.TYPE_NAME_PLACEHOLDER')"
              />
            </div>

            <div>
              <label class="block mb-1 text-sm font-medium text-n-slate-12">
                {{ t('LOCATIONS.FORM.DESCRIPTION') }}
              </label>
              <textarea
                v-model="description"
                class="w-full px-3 py-2 border rounded-lg border-n-weak bg-white text-n-slate-12 focus:ring-2 focus:ring-n-blue-9"
                :placeholder="t('LOCATIONS.FORM.DESCRIPTION_PLACEHOLDER')"
                rows="3"
              />
            </div>

            <div>
              <label class="block mb-1 text-sm font-medium text-n-slate-12">
                {{ t('LOCATIONS.FORM.PARENT_LOCATION') }}
              </label>
              <select
                v-model="parentLocationId"
                class="w-full px-3 py-2 border rounded-lg border-n-weak bg-white text-n-slate-12 focus:ring-2 focus:ring-n-blue-9"
              >
                <option
                  v-for="option in parentLocationOptions"
                  :key="option.value"
                  :value="option.value"
                  v-html="option.label"
                />
              </select>
            </div>
          </div>
        </div>

        <div class="p-6 bg-white border rounded-lg border-n-weak">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-lg font-semibold text-n-slate-12">
              {{ t('LOCATIONS.FORM.ADDRESS_SECTION') }}
            </h2>
            <label class="flex items-center gap-2 cursor-pointer">
              <input
                v-model="hasAddress"
                type="checkbox"
                class="w-4 h-4 rounded border-n-weak text-n-blue-9 focus:ring-n-blue-9"
              />
              <span class="text-sm font-medium text-n-slate-12">
                {{ t('LOCATIONS.FORM.HAS_ADDRESS') }}
              </span>
            </label>
          </div>

          <transition
            enter-active-class="transition-all duration-200 ease-out"
            leave-active-class="transition-all duration-200 ease-in"
            enter-from-class="opacity-0 max-h-0"
            enter-to-class="opacity-100 max-h-[2000px]"
            leave-from-class="opacity-100 max-h-[2000px]"
            leave-to-class="opacity-0 max-h-0"
          >
            <div v-show="hasAddress" class="space-y-4 overflow-hidden">
              <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div>
                  <label class="block mb-1 text-sm font-medium text-n-slate-12">
                    {{ t('LOCATIONS.FORM.ADDRESS.STREET') }} *
                  </label>
                  <input
                    v-model="street"
                    type="text"
                    class="w-full px-3 py-2 border rounded-lg border-n-weak bg-white text-n-slate-12 focus:ring-2 focus:ring-n-blue-9"
                    :placeholder="t('LOCATIONS.FORM.ADDRESS.STREET_PLACEHOLDER')"
                  />
                </div>
                <div class="grid grid-cols-2 gap-4">
                  <div>
                    <label class="block mb-1 text-sm font-medium text-n-slate-12">
                      {{ t('LOCATIONS.FORM.ADDRESS.EXTERIOR_NUMBER') }} *
                    </label>
                    <input
                      v-model="exteriorNumber"
                      type="text"
                      class="w-full px-3 py-2 border rounded-lg border-n-weak bg-white text-n-slate-12 focus:ring-2 focus:ring-n-blue-9"
                    />
                  </div>
                  <div>
                    <label class="block mb-1 text-sm font-medium text-n-slate-12">
                      {{ t('LOCATIONS.FORM.ADDRESS.INTERIOR_NUMBER') }}
                    </label>
                    <input
                      v-model="interiorNumber"
                      type="text"
                      class="w-full px-3 py-2 border rounded-lg border-n-weak bg-white text-n-slate-12 focus:ring-2 focus:ring-n-blue-9"
                    />
                  </div>
                </div>
              </div>

              <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div>
                  <label class="block mb-1 text-sm font-medium text-n-slate-12">
                    {{ t('LOCATIONS.FORM.ADDRESS.NEIGHBORHOOD') }} *
                  </label>
                  <input
                    v-model="neighborhood"
                    type="text"
                    class="w-full px-3 py-2 border rounded-lg border-n-weak bg-white text-n-slate-12 focus:ring-2 focus:ring-n-blue-9"
                  />
                </div>
                <div>
                  <label class="block mb-1 text-sm font-medium text-n-slate-12">
                    {{ t('LOCATIONS.FORM.ADDRESS.POSTAL_CODE') }} *
                  </label>
                  <input
                    v-model="postalCode"
                    type="text"
                    class="w-full px-3 py-2 border rounded-lg border-n-weak bg-white text-n-slate-12 focus:ring-2 focus:ring-n-blue-9"
                  />
                </div>
              </div>

              <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div>
                  <label class="block mb-1 text-sm font-medium text-n-slate-12">
                    {{ t('LOCATIONS.FORM.ADDRESS.CITY') }} *
                  </label>
                  <input
                    v-model="city"
                    type="text"
                    class="w-full px-3 py-2 border rounded-lg border-n-weak bg-white text-n-slate-12 focus:ring-2 focus:ring-n-blue-9"
                  />
                </div>
                <div>
                  <label class="block mb-1 text-sm font-medium text-n-slate-12">
                    {{ t('LOCATIONS.FORM.ADDRESS.STATE') }} *
                  </label>
                  <input
                    v-model="state"
                    type="text"
                    class="w-full px-3 py-2 border rounded-lg border-n-weak bg-white text-n-slate-12 focus:ring-2 focus:ring-n-blue-9"
                  />
                </div>
              </div>

              <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div>
                  <label class="block mb-1 text-sm font-medium text-n-slate-12">
                    {{ t('LOCATIONS.FORM.ADDRESS.EMAIL') }}
                  </label>
                  <input
                    v-model="email"
                    type="email"
                    class="w-full px-3 py-2 border rounded-lg border-n-weak bg-white text-n-slate-12 focus:ring-2 focus:ring-n-blue-9"
                  />
                </div>
                <div>
                  <label class="block mb-1 text-sm font-medium text-n-slate-12">
                    {{ t('LOCATIONS.FORM.ADDRESS.PHONE') }}
                  </label>
                  <input
                    v-model="phone"
                    type="tel"
                    class="w-full px-3 py-2 border rounded-lg border-n-weak bg-white text-n-slate-12 focus:ring-2 focus:ring-n-blue-9"
                  />
                </div>
              </div>

              <div>
                <label class="block mb-1 text-sm font-medium text-n-slate-12">
                  {{ t('LOCATIONS.FORM.ADDRESS.WEBPAGE') }}
                </label>
                <input
                  v-model="webpage"
                  type="url"
                  class="w-full px-3 py-2 border rounded-lg border-n-weak bg-white text-n-slate-12 focus:ring-2 focus:ring-n-blue-9"
                />
              </div>

              <div>
                <label class="block mb-1 text-sm font-medium text-n-slate-12">
                  {{ t('LOCATIONS.FORM.ADDRESS.ESTABLISHMENT_SUMMARY') }}
                </label>
                <textarea
                  v-model="establishmentSummary"
                  class="w-full px-3 py-2 border rounded-lg border-n-weak bg-white text-n-slate-12 focus:ring-2 focus:ring-n-blue-9"
                  rows="3"
                />
              </div>
            </div>
          </transition>
        </div>

        <div class="flex justify-end gap-3">
          <button
            type="button"
            class="px-4 py-2 text-sm font-medium transition-colors rounded-lg text-n-slate-11 hover:bg-n-slate-3"
            @click="handleCancel"
          >
            {{ t('LOCATIONS.FORM.CANCEL') }}
          </button>
          <button
            type="submit"
            class="px-4 py-2 text-sm font-medium text-white transition-colors rounded-lg bg-n-blue-9 hover:bg-n-blue-10 disabled:opacity-50 disabled:cursor-not-allowed"
            :disabled="isSubmitting"
          >
            {{
              isEditMode
                ? t('LOCATIONS.FORM.UPDATE')
                : t('LOCATIONS.FORM.CREATE')
            }}
          </button>
        </div>
      </div>
    </form>
  </div>
</template>
