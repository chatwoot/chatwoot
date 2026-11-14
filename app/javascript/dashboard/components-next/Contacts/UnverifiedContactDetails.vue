<script setup>
// The email or phone number a visitor typed on the website widget or the API channel's public API
// and that was not saved on the contact (UnprovenContactMergeGuard keeps it in
// additional_attributes as claimed_email / claimed_phone_number). The agent confirms it, which
// makes it the contact's own, or, when another contact already holds it, opens that contact to
// merge the two after checking.
//
// The contact page reads its contact through the store getter, which camelizes every key, nested
// ones included (additionalAttributes.claimedEmail); the conversation panel passes the raw
// payload. Both shapes are read.
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import {
  CONTACT_FIELD_LABELS,
  requestErrorMessage,
} from 'dashboard/helper/requestErrorMessage';
import ContactAPI from 'dashboard/api/contacts';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  contact: { type: Object, required: true },
});

// The contact page edits a local copy of the contact and posts all of it on save. `settled` hands
// it what changed (camelized, like that copy) so it can apply just that and keep unsaved edits;
// otherwise a later save would bring back what was just settled.
const emit = defineEmits(['settled']);

const { t } = useI18n();
const store = useStore();
const holders = ref({});
const updatingField = ref(null);

const CLAIMS = [
  {
    field: 'email',
    claimKey: 'claimed_email',
    camelKey: 'claimedEmail',
    camelField: 'email',
    label: t('CONTACT_PANEL.UNVERIFIED_DETAILS.EMAIL'),
  },
  {
    field: 'phone_number',
    claimKey: 'claimed_phone_number',
    camelKey: 'claimedPhoneNumber',
    camelField: 'phoneNumber',
    label: t('CONTACT_PANEL.UNVERIFIED_DETAILS.PHONE_NUMBER'),
  },
];

const claims = computed(() => {
  const attributes =
    props.contact.additional_attributes ||
    props.contact.additionalAttributes ||
    {};
  return CLAIMS.map(claim => ({
    ...claim,
    value: attributes[claim.claimKey] || attributes[claim.camelKey],
  })).filter(claim => claim.value);
});

// An exact match through the contacts filter (email compared case-insensitively there): a text
// search matches substrings of names and identifiers too and pages its results, so the holder can
// fall off the first page.
const findHolder = async claim => {
  try {
    const {
      data: { payload },
    } = await ContactAPI.filter(1, 'name', {
      payload: [
        {
          attribute_key: claim.field,
          filter_operator: 'equal_to',
          values: [claim.value],
          query_operator: null,
        },
      ],
    });
    return payload.find(other => other.id !== props.contact.id) || null;
  } catch {
    return null;
  }
};

// Lookups for a contact the panel has already moved away from are dropped: answering out of order,
// they would show the previous contact's holder on the current one.
let latestLookup = 0;
watch(
  () =>
    [
      props.contact.id,
      ...claims.value.map(claim => `${claim.field}:${claim.value}`),
    ].join('|'),
  async () => {
    latestLookup += 1;
    const lookup = latestLookup;
    holders.value = {};
    const entries = await Promise.all(
      claims.value.map(async claim => [claim.field, await findHolder(claim)])
    );
    if (lookup === latestLookup) holders.value = Object.fromEntries(entries);
  },
  { immediate: true }
);

const settle = async (claim, attributes, successMessage) => {
  updatingField.value = claim.field;
  try {
    await store.dispatch('contacts/update', {
      id: props.contact.id,
      ...attributes,
      additional_attributes: { [claim.claimKey]: null },
    });
    useAlert(successMessage);
    emit('settled', {
      changes: attributes[claim.field]
        ? { [claim.camelField]: attributes[claim.field] }
        : {},
      claimKey: claim.camelKey,
    });
  } catch (error) {
    useAlert(
      requestErrorMessage(
        error,
        t,
        'CONTACT_PANEL.UNVERIFIED_DETAILS.ERROR',
        CONTACT_FIELD_LABELS
      )
    );
  } finally {
    updatingField.value = null;
  }
};

const confirmClaim = claim =>
  settle(
    claim,
    { [claim.field]: claim.value },
    t('CONTACT_PANEL.UNVERIFIED_DETAILS.CONFIRMED')
  );
const dismissClaim = claim =>
  settle(claim, {}, t('CONTACT_PANEL.UNVERIFIED_DETAILS.DISMISSED'));
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <div
    v-if="claims.length"
    class="flex flex-col w-full gap-3 p-3 rounded-lg outline outline-1 outline-n-amber-6 bg-n-amber-2"
  >
    <div class="flex flex-col gap-1">
      <span class="text-sm font-medium text-n-amber-11">
        {{ t('CONTACT_PANEL.UNVERIFIED_DETAILS.TITLE') }}
      </span>
      <span class="text-xs text-n-slate-11">
        {{ t('CONTACT_PANEL.UNVERIFIED_DETAILS.DESCRIPTION') }}
      </span>
    </div>
    <div
      v-for="claim in claims"
      :key="claim.field"
      class="flex flex-col gap-1.5"
    >
      <span class="text-xs text-n-slate-11">
        {{ claim.label }}
      </span>
      <span class="text-sm break-all text-n-slate-12">{{ claim.value }}</span>
      <router-link
        v-if="holders[claim.field]"
        :to="{
          name: 'contacts_edit',
          params: { contactId: holders[claim.field].id },
        }"
        class="text-xs text-n-blue-11 hover:underline"
      >
        {{
          t('CONTACT_PANEL.UNVERIFIED_DETAILS.HELD_BY', {
            name: holders[claim.field].name,
          })
        }}
      </router-link>
      <div class="flex gap-2">
        <Button
          v-if="!holders[claim.field]"
          :label="t('CONTACT_PANEL.UNVERIFIED_DETAILS.CONFIRM')"
          size="xs"
          color="amber"
          :is-loading="updatingField === claim.field"
          :disabled="!!updatingField"
          @click="confirmClaim(claim)"
        />
        <Button
          :label="t('CONTACT_PANEL.UNVERIFIED_DETAILS.DISMISS')"
          size="xs"
          variant="faded"
          color="slate"
          :disabled="!!updatingField"
          @click="dismissClaim(claim)"
        />
      </div>
    </div>
  </div>
</template>
