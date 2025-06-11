<template>
    <div class="flex items-start">
        <div class="rounded-full px-3 py-2 flex items-center justify-center" :class="{
            'bg-[#EBF9F1] text-[#1F9254]': data.toLowerCase() === 'paid' || data.toLowerCase() === 'success',
            'bg-[#FEF2E5] text-[#CD6200]': data.toLowerCase() === 'pending',
            'bg-[#FBE7E8] text-[#A30D11]': data.toLowerCase() === 'failed' || data.toLowerCase() === 'expired',
        }">
            <span class="text-xs font-medium">
                {{ $t(`BILLING.STATUS_PAYMENT.${data}`) }}
            </span>
        </div>
    </div>
</template>

<script setup>
const props = defineProps({
    data: {
        type: String,
        default: '',
    }
})
</script>