<script setup>
import Input from 'dashboard/components-next/input/Input.vue';
// import Button from 'dashboard/components-next/input/Button.vue';
import { ref, watch } from 'vue';
import { useAlert } from 'dashboard/composables';
import vouchers from '../../../../../api/vouchers';
import { useAccount } from 'dashboard/composables/useAccount';

const modelVoucher = defineModel()

const props = defineProps({
    subscriptionPlanId: {
        type: Number,
        required: true,
    },
    selectedPrice: {
        type: Number,
        required: true,
    },
    billingCycle: {
        type: String,
        default: 'monthly',
    },
})

const { accountId } = useAccount();

const voucherCode = ref('')

const isSubmitting = defineModel('isValidatingVoucher')
async function validateVoucher(abortController) {
    try {
        if (isSubmitting.value || !voucherCode.value || !props.subscriptionPlanId) {
            return
        }

        isSubmitting.value = true

        const result = await vouchers.preview({
            subscription_plan_id: props.subscriptionPlanId,
            voucher_code: voucherCode.value?.trim() || undefined,
            account_id: accountId.value,
            price: Number(props.selectedPrice),
            billing_cycle: props.billingCycle,
        })
        if (abortController?.signal?.aborted) {
            return
        }
        modelVoucher.value = result.data
    }
    catch (err) {
        // Clear voucher jika error (tidak valid untuk billing cycle ini)
        clearVoucher()
        useAlert(err?.response?.data?.error || err?.toString())
    }
    finally {
        isSubmitting.value = false
    }
}

function clearVoucher() {
    modelVoucher.value = undefined
    voucherCode.value = ''
}

// Watch price AND billing cycle changes - gabungkan jadi satu watch
watch(() => [props.selectedPrice, props.billingCycle], ([newPrice, newCycle], [oldPrice, oldCycle], onCleanup) => {
    const abortController = new AbortController()
    onCleanup(() => {
        abortController.abort()
    })
    
    // Hanya re-validate jika voucher sudah ada
    if (voucherCode.value) {
        isSubmitting.value = false
        validateVoucher(abortController)
    }
}, { immediate: false })
</script>

<template>
    <div>
        <!-- <div v-if="modelVoucher" class="flex flex-row mt-2 gap-2 items-center rounded border px-3 py-2">
            <div class="flex-1 flex flex-col">
                <span class="font-medium">{{ $t('BILLING.DISCOUNT.SUCCESS_APPLY') }}</span>
                <span class="text-sm">{{ voucherCode }}</span>
            </div>
            <woot-button type="button" @click="clearVoucher" class="px-5">{{
                $t('BILLING.DISCOUNT.CLEAR_VOUCHER_BTN')
            }}</woot-button>
        </div> -->
        <form class="!p-0" @submit.prevent="() => validateVoucher()">
            <div class="flex flex-row mt-2 gap-2">
                <div class="flex flex-col flex-1">
                    <Input v-model="voucherCode" class="w-full" :disabled="modelVoucher"
                        :placeholder="$t('BILLING.DISCOUNT.INPUT_PLACEHOLDER')" />
                    <Transition>
                        <span class="text-xs" v-show="modelVoucher">{{ $t('BILLING.DISCOUNT.SUCCESS_APPLY') }}</span>
                    </Transition>
                </div>
                <woot-button v-if="!modelVoucher" :is-loading="isSubmitting"
                    :disabled="isSubmitting || !voucherCode.trim()" class="px-5">{{
                        $t('BILLING.DISCOUNT.APPLY_BTN')
                    }}</woot-button>
                <woot-button v-else type="button" @click="clearVoucher" class="px-5">{{
                    $t('BILLING.DISCOUNT.CLEAR_VOUCHER_BTN')
                }}</woot-button>
            </div>
        </form>
    </div>
</template>

<style scoped>
.v-enter-active,
.v-leave-active {
    transition: opacity 0.3s ease;
}

.v-enter-from,
.v-leave-to {
    opacity: 0;
}
</style>