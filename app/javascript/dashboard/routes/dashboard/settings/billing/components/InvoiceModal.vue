<script setup>
import { useI18n } from 'vue-i18n';
import { getPlanIcon } from '../billing-icon-utils'
import Button from 'dashboard/components-next/button/Button.vue';
import { useInterval } from '@vueuse/core';

const { locale } = useI18n()

const props = defineProps({
    data: {
        type: Object,
    },
})

function formatDate(dateString) {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat(locale.value || 'id-ID', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
    }).format(date);
}

function copyTotal() {
    let price = `${props.data.price}`
    if (price && price.endsWith('.0')) {
        price = price.substring(0, price.length - 2)
    }
    navigator.clipboard.writeText(price);
}

const intervalCounter = useInterval(() => 1000)

function formatTimeLeft(expiryDate) {
    const diffMs = new Date(expiryDate) - new Date();
    if (diffMs <= 0) {
        location.reload()
        return "00:00:00"
    }

    const totalSeconds = Math.floor(diffMs / 1000);
    const hours = String(Math.floor(totalSeconds / 3600)).padStart(2, "0");
    const minutes = String(Math.floor((totalSeconds % 3600) / 60)).padStart(2, "0");
    const seconds = String(totalSeconds % 60).padStart(2, "0");

    return `${hours}:${minutes}:${seconds}`;
}

</script>

<template>
    <div class="flex flex-row gap-3">
        <div class="bg-n-alpha-3 shadow-md modal-container rounded-xl">
            <div class="flex items-center justify-center mt-5">
                <span class="text-[#2C4D3D] font-bold text-xl">{{ $t('BILLING.INVOICE.TITLE') }}</span>
            </div>

            <div class="p-5 flex flex-col gap-4">
                <div
                    class="rounded-lg w-full p-4 bg-gradient-to-t from-[#2F6B2B] to-[#52964D] flex flex-row gap-2 text-white">
                    <div class="flex-1 flex flex-col gap-3 justify-around">
                        <img src="dashboard/assets/images/brand_jangkau_light.png" width="180">
                        <span>sales@jangkau.ai</span>
                    </div>
                    <div class="flex-1 flex flex-col items-end gap-2">
                        <span class="text-end text-sm font-bold">sales@jangkau.ai</span>
                        <span class="text-end text-sm">Jl. Sidomukti No.14, Sukaluyu,<br>Kec. Cibeunying Kaler, Kota
                            Bandung,<br>Jawa Barat 40123</span>
                    </div>
                </div>

                <div class="text-sm">
                    <div class="rounded-lg bg-[#E9F5EC] flex flex-row w-full p-4">
                        <div class="flex-1 flex flex-col gap-3">
                            <span class="font-bold text-[#2C4D3D]">{{ $t('BILLING.INVOICE.NO_INVOICE') }}</span>
                            <div class="flex flex-col gap-1">
                                <span>#{{ props.data.transactionId }}</span>
                                <span>{{ $t('BILLING.INVOICE.PUBLISHED_DATE', {
                                    date: formatDate(props.data.created_at),
                                }) }}</span>
                                <!-- <span>{{ $t('BILLING.INVOICE.DUE_DATE', {
                                date: formatDate(props.data.ends_at),
                            }) }}</span> -->
                            </div>
                        </div>
                        <div class="flex-1 flex flex-col items-end text-end gap-3">
                            <span class="font-bold text-[#2C4D3D]">{{ $t('BILLING.INVOICE.FOR_ID') }}</span>
                            <div class="flex flex-col gap-1">
                                <span class="font-medium">{{ props.data.user.name }}</span>
                                <span>{{ props.data.user.email }}</span>
                                <span>{{ props.data.user.phone }}</span>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="flex flex-col gap-2">
                    <div>
                        <span class="font-bold text-[#2C4D3D]">{{ $t('BILLING.INVOICE.DETAIL_PAYMENT') }}</span>
                    </div>
                    <div class="flex flex-row gap-3">
                        <div class="flex-1 flex flex-row gap-3">
                            <div class="h-16 w-16 rounded-lg bg-[#D9EFC4] flex justify-center items-center p-1">
                                <img :src="getPlanIcon(props.data.package_type)" style="width: 50px">
                            </div>
                            <div class="flex flex-col">
                                <span class="font-bold text-[#52964D]">{{ props.data?.package }}</span>
                                <span class="text-sm">{{ $t('BILLING.TABLE.HEADER.DURATION') }}</span>
                                <span class="text-sm font-bold">{{ props.data.duration }}</span>
                            </div>
                        </div>
                        <div class="flex flex-col items-end justify-end">
                            <div class="flex flex-col text-end">
                                <span class="text-sm">{{ $t('BILLING.INVOICE.PRICE_LABEL') }}</span>
                                <span class="text-sm font-bold">{{ new Intl.NumberFormat(locale ||
                                    'id').format(props.data.price) }}</span>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="w-full h-[1px] bg-[#EFEFEF]"></div>

                <div class="flex flex-row justify-end">
                    <div class="flex flex-row gap-6">
                        <span>{{ $t('BILLING.INVOICE.TOTAL') }}</span>
                        <span class="text-[#2C4D3D] font-bold">{{ new Intl.NumberFormat(locale ||
                            'id').format(props.data.price) }}</span>
                    </div>
                </div>
            </div>
        </div>
        <div class="bg-n-alpha-3 shadow-md modal-container rounded-xl h-[min-content] w-[275px]">
            <div class="flex mx-5 mt-5">
                <span class="text-[#2C4D3D] font-bold">{{ $t('BILLING.INVOICE.PAYMENT_METHOD') }}</span>
            </div>

            <div class="p-5 flex flex-col gap-3">
                <span class="text-lg font-bold">{{ props.data.payment_method }}</span>

                <span :key="`time-${intervalCounter}`" class="text-sm" v-if="props.data?.status === 'pending'" v-html="$t('BILLING.INVOICE.PAYMENT_WAITING', {
                    time: props.data?.expiry_date ? formatTimeLeft(props.data?.expiry_date) : undefined,
                })"></span>

                <div class="w-full h-[1px] bg-[#EFEFEF]"></div>

                <div class="flex flex-col gap-1">
                    <span>{{ $t('BILLING.INVOICE.PAY_TOTAL') }}</span>
                    <div class="flex flex-row gap-1 items-center">
                        <span class="text-[#2C4D3D] text-lg font-bold">{{ new Intl.NumberFormat(locale
                            ||
                            'id').format(props.data.price) }}</span>
                        <Button class="h-8 w-8" icon="i-lucide-copy" :bgColor="'bg-red'" @click="() => copyTotal()" />
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>