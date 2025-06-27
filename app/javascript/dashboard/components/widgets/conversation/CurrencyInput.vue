<template>
  <input
    ref="inputRef"
    type="text"
    :value="displayValue"
    inputmode="decimal"
    placeholder="0.00"
    @beforeinput="onBeforeInput"
    @input="onInput"
    @focus="onFocus"
    @blur="onBlur"
    style="width: 200px; font-size: 1.1em"
    autocomplete="off"
  />
</template>

<script setup>
import { ref, computed, watch } from 'vue'

const props = defineProps({
  modelValue: [String, Number],
  currencySymbol: {
    type: String,
    default: '₹'
  }
})
const emit = defineEmits(['update:modelValue'])

const inputRef = ref(null)

const symbolLength = computed(() => props.currencySymbol.length)

const displayValue = computed(() => {
  let val = props.modelValue ?? ''
  // Always ensure the symbol is at the start
  if (!val || typeof val !== 'string') val = String(val ?? '')
  if (!val.startsWith(props.currencySymbol)) {
    val = val.replace(props.currencySymbol, '')
    return props.currencySymbol + val
  }
  return val
})

// Prevent typing before the symbol or deleting the symbol
function onBeforeInput(e) {
  const input = e.target
  // Prevent caret before the symbol
  if (input.selectionStart < symbolLength.value) {
    e.preventDefault()
    input.setSelectionRange(symbolLength.value, symbolLength.value)
    return
  }
  // Prevent entering invalid characters
  if (e.data && !/[\d.]/.test(e.data) && e.inputType === 'insertText') {
    e.preventDefault()
  }
}

// On input, filter and format value, always restore symbol if missing
function onInput(e) {
  let raw = e.target.value
  // Ensure symbol is always present at the start
  if (!raw.startsWith(props.currencySymbol)) {
    raw = props.currencySymbol + raw.replace(props.currencySymbol, '')
  }
  // Remove all except digits and dot after symbol
  raw = props.currencySymbol + raw.slice(symbolLength.value).replace(/[^\d.]/g, '')
  // Only allow one dot and two decimals
  const parts = raw.slice(symbolLength.value).split('.')
  let numeric = parts[0]
  if (parts[1] !== undefined) {
    numeric += '.' + parts[1].slice(0, 2)
  }
  // Prevent leading zeros (except "0." case)
  if (numeric.startsWith('00')) numeric = '0'
  if (numeric.startsWith('0') && numeric[1] && numeric[1] !== '.') numeric = numeric.replace(/^0+/, '')
  emit('update:modelValue', numeric)
}

// On focus, move caret after symbol if needed
function onFocus(e) {
  setTimeout(() => {
    if (e.target.selectionStart < symbolLength.value) {
      e.target.setSelectionRange(symbolLength.value, symbolLength.value)
    }
    // If input is empty or only symbol, keep caret after symbol
    if (e.target.value === props.currencySymbol) {
      e.target.setSelectionRange(symbolLength.value, symbolLength.value)
    }
  }, 0)
}

// On blur, format to two decimals if possible
function onBlur(e) {
  let value = parseFloat(props.modelValue)
  if (!isNaN(value)) {
    emit('update:modelValue', value.toFixed(2))
  } else {
    emit('update:modelValue', '')
  }
}
</script>
