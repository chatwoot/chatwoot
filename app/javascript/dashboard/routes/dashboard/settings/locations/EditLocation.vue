<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import LocationsAPI from 'dashboard/api/locations';

export default {
  components: {
    NextButton,
    Spinner,
  },
  props: {
    selectedLocation: {
      type: Object,
      required: true,
    },
  },
  emits: ['close'],
  data() {
    return {
      isLoading: false,
      name: '',
      description: '',
      typeName: '',
      parentLocations: [],
      hasAddress: false,
      addressId: null,
      street: '',
      exteriorNumber: '',
      interiorNumber: '',
      neighborhood: '',
      postalCode: '',
      city: '',
      state: '',
      email: '',
      phone: '',
      webpage: '',
      establishmentSummary: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'locations/getUIFlags',
      locations: 'locations/getLocations',
    }),
    pageTitle() {
      return `${this.$t('LOCATIONS.FORM.EDIT_TITLE')} - ${this.name}`;
    },
    parentLocationOptions() {
      return this.locations.filter(loc => loc.id !== this.selectedLocation.id);
    },
    isAddressValid() {
      if (!this.hasAddress) return true;

      return (
        this.street &&
        this.exteriorNumber &&
        this.neighborhood &&
        this.postalCode &&
        this.city &&
        this.state
      );
    },
    isFormValid() {
      return this.name && this.isAddressValid;
    },
  },
  async mounted() {
    await this.loadLocationData();
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    async loadLocationData() {
      this.isLoading = true;
      try {
        const { data } = await LocationsAPI.show(this.selectedLocation.id);
        const location = data;

        this.name = location.name || '';
        this.description = location.description || '';
        this.typeName = location.type_name || '';
        this.parentLocations = location.parent_locations || [];

        if (location.address) {
          this.hasAddress = true;
          this.addressId = location.address.id;
          this.street = location.address.street || '';
          this.exteriorNumber = location.address.exterior_number || '';
          this.interiorNumber = location.address.interior_number || '';
          this.neighborhood = location.address.neighborhood || '';
          this.postalCode = location.address.postal_code || '';
          this.city = location.address.city || '';
          this.state = location.address.state || '';
          this.email = location.address.email || '';
          this.phone = location.address.phone || '';
          this.webpage = location.address.webpage || '';
          this.establishmentSummary = location.address.establishment_summary || '';
        }
      } catch (error) {
        useAlert(this.$t('LOCATIONS.FORM.LOAD_ERROR'));
        this.onClose();
      } finally {
        this.isLoading = false;
      }
    },
    async editLocation() {
      if (!this.isFormValid) return;

      const payload = {
        id: this.selectedLocation.id,
        name: this.name,
        description: this.description || null,
        type_name: this.typeName || null,
        parent_location_ids: this.parentLocations.map(l => l.id),
      };

      if (this.hasAddress) {
        payload.address_attributes = {
          id: this.addressId,
          street: this.street,
          exterior_number: this.exteriorNumber,
          interior_number: this.interiorNumber || null,
          neighborhood: this.neighborhood,
          postal_code: this.postalCode,
          city: this.city,
          state: this.state,
          email: this.email || null,
          phone: this.phone || null,
          webpage: this.webpage || null,
          establishment_summary: this.establishmentSummary || null,
        };
      } else if (this.addressId) {
        // Mark address for deletion if checkbox is unchecked
        payload.address_attributes = {
          id: this.addressId,
          _destroy: true,
        };
      }

      try {
        await this.$store.dispatch('locations/update', payload);
        useAlert(this.$t('LOCATIONS.FORM.UPDATE_SUCCESS'));
        setTimeout(() => this.onClose(), 10);
        await this.$store.dispatch('locations/get');
      } catch (error) {
        const errorMessage =
          error?.response?.data?.errors?.[0] ||
          error.message ||
          this.$t('LOCATIONS.FORM.SUBMIT_ERROR');
        useAlert(errorMessage);
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header :header-title="pageTitle" />
    <div v-if="isLoading" class="flex justify-center p-8">
      <spinner />
    </div>
    <form v-else class="flex flex-wrap mx-0" @submit.prevent="editLocation">
      <!-- Name -->
      <woot-input
        v-model="name"
        class="w-full"
        :label="$t('LOCATIONS.FORM.NAME')"
        :placeholder="$t('LOCATIONS.FORM.NAME_PLACEHOLDER')"
        :error="!name ? $t('LOCATIONS.FORM.NAME_REQUIRED') : ''"
        required
      />

      <!-- Type Name -->
      <woot-input
        v-model="typeName"
        class="w-full"
        :label="$t('LOCATIONS.FORM.TYPE_NAME')"
        :placeholder="$t('LOCATIONS.FORM.TYPE_NAME_PLACEHOLDER')"
      />

      <!-- Description -->
      <label class="w-full">
        {{ $t('LOCATIONS.FORM.DESCRIPTION') }}
        <textarea
          v-model="description"
          rows="3"
          :placeholder="$t('LOCATIONS.FORM.DESCRIPTION_PLACEHOLDER')"
          class="w-full"
        />
      </label>

      <!-- Parent Location -->
      <div class="w-full">
        <label class="mb-1 block">
          {{ $t('LOCATIONS.FORM.PARENT_LOCATION') }}
        </label>
        <multiselect
          v-model="parentLocations"
          :options="parentLocationOptions"
          track-by="id"
          label="name"
          multiple
          :close-on-select="false"
          :clear-on-select="false"
          hide-selected
          :placeholder="$t('LOCATIONS.FORM.PARENT_LOCATION_PLACEHOLDER')"
          :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
          :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
        />
      </div>

      <!-- Has Address Toggle -->
      <div class="flex items-center w-full gap-2 my-4">
        <input v-model="hasAddress" type="checkbox" :value="true" />
        <label>
          {{ $t('LOCATIONS.FORM.HAS_ADDRESS') }}
        </label>
      </div>

      <!-- Address Fields (conditional) -->
      <template v-if="hasAddress">
        <div class="w-full">
          <h3 class="text-base font-medium mb-2">
            {{ $t('LOCATIONS.FORM.ADDRESS_SECTION') }}
          </h3>
        </div>

        <div class="w-2/3 ltr:pr-2 rtl:pl-2">
          <woot-input
            v-model="street"
            :label="$t('LOCATIONS.FORM.ADDRESS.STREET')"
            :placeholder="$t('LOCATIONS.FORM.ADDRESS.STREET_PLACEHOLDER')"
            required
          />
        </div>

        <div class="w-1/6 ltr:pr-2 rtl:pl-2">
          <woot-input
            v-model="exteriorNumber"
            :label="$t('LOCATIONS.FORM.ADDRESS.EXTERIOR_NUMBER')"
            required
          />
        </div>

        <div class="w-1/6">
          <woot-input
            v-model="interiorNumber"
            :label="$t('LOCATIONS.FORM.ADDRESS.INTERIOR_NUMBER')"
          />
        </div>

        <div class="w-1/2 ltr:pr-2 rtl:pl-2">
          <woot-input
            v-model="neighborhood"
            :label="$t('LOCATIONS.FORM.ADDRESS.NEIGHBORHOOD')"
            required
          />
        </div>

        <div class="w-1/2">
          <woot-input
            v-model="postalCode"
            :label="$t('LOCATIONS.FORM.ADDRESS.POSTAL_CODE')"
            required
          />
        </div>

        <div class="w-1/2 ltr:pr-2 rtl:pl-2">
          <woot-input
            v-model="city"
            :label="$t('LOCATIONS.FORM.ADDRESS.CITY')"
            required
          />
        </div>

        <div class="w-1/2">
          <woot-input
            v-model="state"
            :label="$t('LOCATIONS.FORM.ADDRESS.STATE')"
            required
          />
        </div>

        <div class="w-1/2 ltr:pr-2 rtl:pl-2">
          <woot-input
            v-model="email"
            type="email"
            :label="$t('LOCATIONS.FORM.ADDRESS.EMAIL')"
          />
        </div>

        <div class="w-1/2">
          <woot-input
            v-model="phone"
            :label="$t('LOCATIONS.FORM.ADDRESS.PHONE')"
          />
        </div>

        <woot-input
          v-model="webpage"
          class="w-full"
          type="url"
          :label="$t('LOCATIONS.FORM.ADDRESS.WEBPAGE')"
        />

        <label class="w-full">
          {{ $t('LOCATIONS.FORM.ADDRESS.ESTABLISHMENT_SUMMARY') }}
          <textarea
            v-model="establishmentSummary"
            rows="2"
            class="w-full"
          />
        </label>
      </template>

      <!-- Form Actions -->
      <div class="flex items-center justify-end w-full gap-2 px-0 py-2">
        <NextButton
          faded
          slate
          type="reset"
          :label="$t('LOCATIONS.FORM.CANCEL')"
          @click.prevent="onClose"
        />
        <NextButton
          type="submit"
          :label="$t('LOCATIONS.FORM.UPDATE')"
          :disabled="!isFormValid || uiFlags.isUpdating"
          :is-loading="uiFlags.isUpdating"
        />
      </div>
    </form>
  </div>
</template>
