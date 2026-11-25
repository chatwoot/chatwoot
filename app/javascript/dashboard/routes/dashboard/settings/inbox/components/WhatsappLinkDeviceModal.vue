<script setup>
import { onMounted, computed, ref, watchEffect } from 'vue';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import InboxName from 'dashboard/components/widgets/InboxName.vue';
import Spinner from 'shared/components/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { CAPABILITIES, hasCapability } from 'dashboard/helper/whatsappSession';

const props = defineProps({
  show: { type: Boolean, required: true },
  onClose: { type: Function, required: true },
  isSetup: { type: Boolean, required: false },
  inbox: {
    type: Object,
    required: true,
  },
});

const store = useStore();

const providerConnection = computed(() => props.inbox.provider_connection);
const connection = computed(() => providerConnection.value?.connection);
const qrDataUrl = computed(() => providerConnection.value?.qr_data_url);
const pairingCode = computed(() => providerConnection.value?.pairing_code);
const error = computed(() => providerConnection.value?.error);
// The connector redialling on purpose (a proxy change). Its redial reads `connecting`,
// which is also what a pairing reads as, and the account is paired: shown as the pairing,
// the modal would put up the QR loader for a scan nobody needs.
const reconnecting = computed(
  () =>
    connection.value === 'reconnecting' ||
    (connection.value === 'connecting' && !!providerConnection.value?.rerouting)
);

// Which pairing the operator asked for, not which one the provider has answered with
// yet: the code takes a moment to arrive, and the screen has to say what it is waiting
// for in the meantime. Reset whenever the pairing ends, so the next one starts on the
// QR again, which is the mode that needs nothing from them.
const pairingMode = ref('qr');
const supportsCodePairing = computed(() =>
  hasCapability(props.inbox, CAPABILITIES.CODE_PAIRING)
);

// What the screen shows, which is not the same question as what the operator asked for.
// A provider can answer a code pairing with a QR alongside the code (uazapi keeps
// rotating one), and this component's own request is client-side state that a blip in
// the connection resets. Both together used to hide a perfectly valid code behind the
// QR branch. A code on the record is only ever there because a code was asked for, so
// it decides on its own; the request still decides while nothing has arrived yet.
const displayedPairing = computed(() =>
  pairingMode.value === 'code' || pairingCode.value ? 'code' : 'qr'
);

// A send stall is the one failure that leaves `connection` reading 'open' while the
// inbox cannot answer anyone. That combination breaks the usual reading of this modal:
// setup() only refreshes presence on a connection the provider already considers live,
// so the recovery is re-pairing, and the button for it lives in the open branch below.
const sendStall = computed(() => providerConnection.value?.send_stall);

// Alternative onboarding when WhatsApp's extra device-linking verification blocks
// the QR: install the browser extension and import an already-linked session.
//
// The credentials it hands over are Baileys', and only a Baileys inbox can consume
// them, so the offer follows the capability. Advertising it to a provider that cannot
// accept the import sends the agent through an install and a scan that end in a refused
// request.
const extensionUrl =
  'https://chromewebstore.google.com/detail/fazerai-whatsapp-connecto/nchdjpjplcnggifnemiiclgjplooible';
const supportsSessionImport = computed(() =>
  hasCapability(props.inbox, CAPABILITIES.SESSION_IMPORT)
);

const loading = ref(false);
const showImportDetails = ref(false);

const handleError = e => {
  useAlert(e.message);
  loading.value = false;
};
const setup = () => {
  loading.value = true;
  pairingMode.value = 'qr';
  store
    .dispatch('inboxes/setupChannelProvider', props.inbox.id)
    .catch(handleError);
};
// Asking again is how a code that expired is replaced, so this stays reachable while one
// is already on screen.
const pairWithCode = () => {
  loading.value = true;
  pairingMode.value = 'code';
  store
    .dispatch('inboxes/requestPairingCode', props.inbox.id)
    .then(() => {
      // The connection was already `connecting` when the QR was on screen, so the watcher
      // below never fires and nothing else would stop the button spinning. What comes
      // next is the wait for the code, which the panel shows on its own.
      loading.value = false;
    })
    .catch(handleError);
};
// Only ever the operator asking for it. Closing this screen used to end the pairing on
// the way out, which made a look-and-close cost a fresh code, and on a provider that
// issues one only from a disconnected instance that is a round trip the operator has to
// discover. An attempt nobody completes expires on its own: the provider stops offering
// it, and the poll writes the timeout.
const disconnect = () => {
  loading.value = true;
  store
    .dispatch('inboxes/disconnectChannelProvider', props.inbox.id)
    .catch(handleError);
};

// Deliberately reads the record as it stands rather than refreshing it. Reloading the
// inboxes from here replaces them in the store, which re-renders the settings page this
// modal is mounted inside and takes the modal down with it: the operator clicks the
// button and nothing opens. The connection record is kept current by the cable, and the
// poll behind a live pairing is what refreshes what is on screen.
onMounted(() => {
  if (!connection.value || connection.value === 'close') {
    setup();
  }
});
watchEffect(() => {
  if (connection.value) {
    loading.value = false;
  }
  if (connection.value && connection.value !== 'connecting') {
    pairingMode.value = 'qr';
  }
});
</script>

<template>
  <woot-modal :show="show" size="small" @close="onClose">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header
        :header-title="
          $t(
            'INBOX_MGMT.ADD.WHATSAPP.EXTERNAL_PROVIDER.LINK_DEVICE_MODAL.TITLE'
          )
        "
        :header-content="
          $t(
            'INBOX_MGMT.ADD.WHATSAPP.EXTERNAL_PROVIDER.LINK_DEVICE_MODAL.SUBTITLE'
          )
        "
      />

      <div class="flex flex-col gap-4 p-8 pt-4">
        <div class="flex flex-col gap-4 items-center">
          <InboxName
            :inbox="inbox"
            class="!text-lg"
            with-phone-number
            with-provider-connection-status
          />

          <template
            v-if="
              !connection ||
              connection === 'close' ||
              (error && connection !== 'open')
            "
          >
            <p v-if="error" class="text-red-500 text-center">
              {{ error }}
            </p>
            <Button :is-loading="loading" @click="setup">
              {{
                $t(
                  'INBOX_MGMT.ADD.WHATSAPP.EXTERNAL_PROVIDER.LINK_DEVICE_MODAL.LINK_DEVICE'
                )
              }}
            </Button>

            <!-- The other way in, offered before the pairing starts rather than only
                 during it. A provider can refuse to issue a code once a pairing is
                 already in flight (uazapi answers the state it is in and no code at
                 all), which left the operator having to start the QR they cannot use
                 to reach the option they can. -->
            <Button
              v-if="supportsCodePairing"
              link
              blue
              :is-loading="loading"
              :label="
                $t(
                  'INBOX_MGMT.ADD.WHATSAPP.EXTERNAL_PROVIDER.LINK_DEVICE_MODAL.USE_PAIRING_CODE'
                )
              "
              @click="pairWithCode"
            />
          </template>

          <template v-else-if="reconnecting">
            <p>
              {{
                $t(
                  'INBOX_MGMT.ADD.WHATSAPP.EXTERNAL_PROVIDER.LINK_DEVICE_MODAL.RECONNECTING'
                )
              }}
            </p>
            <Spinner />
          </template>

          <template v-else-if="connection === 'connecting'">
            <template v-if="displayedPairing === 'code'">
              <div v-if="!pairingCode" class="flex flex-col gap-4 items-center">
                <p>
                  {{
                    $t(
                      'INBOX_MGMT.ADD.WHATSAPP.EXTERNAL_PROVIDER.LINK_DEVICE_MODAL.LOADING_PAIRING_CODE'
                    )
                  }}
                </p>
                <Spinner />
              </div>
              <div v-else class="flex flex-col gap-2 items-center">
                <p
                  class="font-mono text-3xl font-semibold tracking-widest select-all text-n-slate-12"
                >
                  {{ pairingCode }}
                </p>
                <!-- Numbered, because this is read by someone holding the phone with
                     one hand: a paragraph makes them find where they are again after
                     every step. -->
                <ol
                  class="max-w-xs pl-5 text-sm list-decimal text-n-slate-11 marker:text-n-slate-10"
                >
                  <li>
                    {{
                      $t(
                        'INBOX_MGMT.ADD.WHATSAPP.EXTERNAL_PROVIDER.LINK_DEVICE_MODAL.PAIRING_CODE_STEP_1'
                      )
                    }}
                  </li>
                  <li>
                    {{
                      $t(
                        'INBOX_MGMT.ADD.WHATSAPP.EXTERNAL_PROVIDER.LINK_DEVICE_MODAL.PAIRING_CODE_STEP_2'
                      )
                    }}
                  </li>
                  <li>
                    {{
                      $t(
                        'INBOX_MGMT.ADD.WHATSAPP.EXTERNAL_PROVIDER.LINK_DEVICE_MODAL.PAIRING_CODE_STEP_3'
                      )
                    }}
                  </li>
                </ol>
                <p class="max-w-xs text-xs text-center text-n-slate-10">
                  {{
                    $t(
                      'INBOX_MGMT.ADD.WHATSAPP.EXTERNAL_PROVIDER.LINK_DEVICE_MODAL.PAIRING_CODE_EXPIRES'
                    )
                  }}
                </p>
              </div>
            </template>

            <template v-else>
              <div v-if="!qrDataUrl" class="flex flex-col gap-4 items-center">
                <p>
                  {{
                    $t(
                      'INBOX_MGMT.ADD.WHATSAPP.EXTERNAL_PROVIDER.LINK_DEVICE_MODAL.LOADING_QRCODE'
                    )
                  }}
                </p>
                <Spinner />
              </div>
              <img
                v-else
                :src="qrDataUrl"
                alt="QR Code"
                class="w-[276px] h-[276px]"
              />
            </template>

            <!-- The way in for an operator who cannot scan: the phone being linked is
                 rarely in the same room as the person doing the setup. Asking again is
                 also how a code that expired is replaced. -->
            <template v-if="supportsCodePairing">
              <Button
                v-if="displayedPairing === 'code'"
                link
                blue
                :is-loading="loading"
                :label="
                  $t(
                    'INBOX_MGMT.ADD.WHATSAPP.EXTERNAL_PROVIDER.LINK_DEVICE_MODAL.USE_QRCODE'
                  )
                "
                @click="setup"
              />
              <Button
                v-else
                link
                blue
                :is-loading="loading"
                :label="
                  $t(
                    'INBOX_MGMT.ADD.WHATSAPP.EXTERNAL_PROVIDER.LINK_DEVICE_MODAL.USE_PAIRING_CODE'
                  )
                "
                @click="pairWithCode"
              />
            </template>
          </template>

          <template v-else-if="connection === 'open'">
            <p v-if="error" class="text-center text-red-500">
              {{ error }}
            </p>
            <p v-else-if="isSetup" class="text-center">
              {{
                $t(
                  'INBOX_MGMT.ADD.WHATSAPP.EXTERNAL_PROVIDER.LINK_DEVICE_MODAL.CONNECTED'
                )
              }}
            </p>
            <div class="flex gap-2">
              <!-- Promoted from ghost while a stall is open: re-pairing stops being the
                   way out of the modal and becomes the only thing that clears the fault. -->
              <Button
                :variant="sendStall ? 'solid' : 'ghost'"
                :color="sendStall ? 'ruby' : 'blue'"
                :is-loading="loading"
                @click="disconnect"
              >
                {{
                  $t(
                    'INBOX_MGMT.ADD.WHATSAPP.EXTERNAL_PROVIDER.LINK_DEVICE_MODAL.DISCONNECT'
                  )
                }}
              </Button>
              <router-link
                v-if="isSetup"
                :to="{
                  name: 'inbox_dashboard',
                  params: { inboxId: inbox.id },
                }"
              >
                <Button
                  solid
                  teal
                  :label="$t('INBOX_MGMT.FINISH.BUTTON_TEXT')"
                />
              </router-link>
            </div>
          </template>

          <!-- Fallback kept available in every non-open state, including while the
               QR is shown: import an already-linked session via the extension. -->
          <div
            v-if="connection !== 'open' && supportsSessionImport"
            class="flex flex-col gap-1 items-center pt-4 mt-2 w-full border-t border-n-weak"
          >
            <p class="text-sm font-medium text-center text-n-slate-12">
              {{
                $t(
                  'INBOX_MGMT.ADD.WHATSAPP.EXTERNAL_PROVIDER.LINK_DEVICE_MODAL.IMPORT_SESSION_TITLE'
                )
              }}
            </p>
            <button
              v-if="!showImportDetails"
              type="button"
              :aria-expanded="showImportDetails"
              class="text-xs underline text-n-slate-11 hover:text-n-slate-12"
              @click="showImportDetails = true"
            >
              {{
                $t(
                  'INBOX_MGMT.ADD.WHATSAPP.EXTERNAL_PROVIDER.LINK_DEVICE_MODAL.IMPORT_SESSION_SHOW_MORE'
                )
              }}
            </button>
            <template v-else>
              <p class="text-sm text-center text-n-slate-11">
                {{
                  $t(
                    'INBOX_MGMT.ADD.WHATSAPP.EXTERNAL_PROVIDER.LINK_DEVICE_MODAL.IMPORT_SESSION_DESC'
                  )
                }}
              </p>
              <a :href="extensionUrl" target="_blank" rel="noopener noreferrer">
                <Button
                  link
                  blue
                  :label="
                    $t(
                      'INBOX_MGMT.ADD.WHATSAPP.EXTERNAL_PROVIDER.LINK_DEVICE_MODAL.IMPORT_SESSION_INSTALL'
                    )
                  "
                />
              </a>
            </template>
          </div>
        </div>
      </div>
    </div>
  </woot-modal>
</template>
