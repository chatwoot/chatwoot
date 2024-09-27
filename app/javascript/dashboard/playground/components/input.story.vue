<script setup>
import { ref } from 'vue';
import Input from './Input.vue';

const textValue = ref('');
const numberValue = ref(0);
const passwordValue = ref('');
</script>

<template>
  <Story title="Components/Input" :layout="{ type: 'grid', width: '300px' }">
    <Variant title="Default">
      <Input v-model="textValue" placeholder="Enter text" />
    </Variant>

    <Variant title="With Label">
      <Input
        v-model="textValue"
        label="Username"
        placeholder="Enter username"
      />
    </Variant>

    <Variant title="Number Input">
      <Input
        v-model="numberValue"
        type="number"
        label="Age"
        placeholder="Enter age"
      />
    </Variant>

    <Variant title="Password Input">
      <Input
        v-model="passwordValue"
        type="password"
        label="Password"
        placeholder="Enter password"
      />
    </Variant>

    <Variant title="With Info Message">
      <Input
        v-model="textValue"
        label="Email"
        placeholder="Enter email"
        message="We'll never share your email with anyone else."
        messageType="info"
      />
    </Variant>

    <Variant title="With Error Message">
      <Input
        v-model="textValue"
        label="Username"
        placeholder="Enter username"
        message="Username is already taken"
        message-type="error"
      />
    </Variant>

    <Variant title="With Success Message">
      <Input
        v-model="textValue"
        label="Username"
        placeholder="Enter username"
        message="Username is available"
        message-type="success"
      />
    </Variant>

    <Variant title="Disabled">
      <Input
        v-model="textValue"
        label="Disabled Input"
        placeholder="Can't type here"
        disabled
      />
    </Variant>

    <Variant title="Custom Input Class">
      <Input
        v-model="textValue"
        label="Custom Style"
        placeholder="Custom input"
        custom-input-class="bg-yellow-100 border-yellow-300"
      />
    </Variant>
  </Story>
</template>
