<script setup>
import { computed, ref, onMounted } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { requiredIf } from '@vuelidate/validators';
import { useI18n } from 'vue-i18n';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  template: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['sendMessage', 'back']);

const { t } = useI18n();

const processedParams = ref({});

const templateName = computed(() => {
  return props.template?.name || '';
});

const templateComponents = computed(() => {
  return props.template?.components || [];
});

const templateString = computed(() => {
  return (
    props.template?.components?.find(component => component.type === 'BODY')
      ?.text || ''
  );
});

const headerComponent = computed(() => {
  return templateComponents.value.find(
    component => component.type === 'HEADER'
  );
});

const footerComponent = computed(() => {
  return templateComponents.value.find(
    component => component.type === 'FOOTER'
  );
});

const buttonComponents = computed(() => {
  return templateComponents.value.filter(
    component => component.type === 'BUTTONS'
  );
});

const interactiveComponents = computed(() => {
  return templateComponents.value.filter(component =>
    ['LIST', 'PRODUCT', 'CATALOG'].includes(component.type)
  );
});

const isInteractiveTemplate = computed(() => {
  const hasInteractiveButtons = buttonComponents.value.some(component =>
    component.buttons?.some(button =>
      ['quick_reply', 'url', 'phone_number', 'catalog_browse'].includes(
        button.type
      )
    )
  );
  return hasInteractiveButtons || interactiveComponents.value.length > 0;
});

const legacyParams = computed(() => {
  const params = {};
  Object.keys(processedParams.value).forEach(key => {
    if (!['header', 'body', 'footer', 'buttons'].includes(key)) {
      params[key] = processedParams.value[key];
    }
  });
  return params;
});

const processVariable = str => {
  return str.replace(/{{|}}/g, '');
};

const processedString = computed(() => {
  return templateString.value.replace(/{{([^}]+)}}/g, (match, variable) => {
    const variableKey = processVariable(variable);
    return processedParams.value[variableKey] || `{{${variable}}}`;
  });
});

const processedStringWithVariableHighlight = computed(() => {
  const variables = templateString.value.match(/{{([^}]+)}}/g) || [];

  return variables.reduce((result, variable) => {
    const variableKey = processVariable(variable);
    const value = processedParams.value[variableKey] || variable;
    return result.replace(
      variable,
      `<span class="break-all text-n-slate-12">${value}</span>`
    );
  }, templateString.value);
});

const rules = computed(() => {
  const paramRules = {};
  Object.keys(processedParams.value).forEach(key => {
    if (
      key === 'header' &&
      processedParams.value.header.location_type === 'location'
    ) {
      // Add specific validation for location parameters
      paramRules[key] = {
        location: {
          latitude: { required: requiredIf(true) },
          longitude: { required: requiredIf(true) },
        },
      };
    } else {
      paramRules[key] = { required: requiredIf(true) };
    }
  });
  return {
    processedParams: paramRules,
  };
});

const v$ = useVuelidate(rules, { processedParams });

const getFieldErrorType = key => {
  if (!v$.value.processedParams[key]?.$error) return 'info';
  return 'error';
};

const generateVariables = () => {
  const allVariables = {};

  // Process body variables
  const bodyVars = templateString.value.match(/{{([^}]+)}}/g) || [];
  if (bodyVars.length > 0) {
    allVariables.body = {};
    bodyVars.forEach(variable => {
      const key = processVariable(variable);
      // Special handling for authentication templates
      if (props.template?.category === 'AUTHENTICATION') {
        if (
          key === '1' ||
          key.toLowerCase().includes('otp') ||
          key.toLowerCase().includes('code')
        ) {
          allVariables.body.otp_code = '';
        } else if (
          key === '2' ||
          key.toLowerCase().includes('expiry') ||
          key.toLowerCase().includes('minute')
        ) {
          allVariables.body.expiry_minutes = '';
        } else {
          allVariables.body[key] = '';
        }
      } else {
        allVariables.body[key] = '';
      }
    });
  }

  // Process header variables
  if (headerComponent.value) {
    if (headerComponent.value.text) {
      // Text headers with variables
      const headerVars = headerComponent.value.text.match(/{{([^}]+)}}/g) || [];
      if (headerVars.length > 0) {
        allVariables.header = {};
        headerVars.forEach(variable => {
          const key = processVariable(variable);
          allVariables.header[key] = '';
        });
      }
    } else if (
      headerComponent.value.format &&
      ['IMAGE', 'VIDEO', 'DOCUMENT'].includes(headerComponent.value.format)
    ) {
      // Media headers need URL input
      allVariables.header = {
        media_url: '',
        media_type: headerComponent.value.format.toLowerCase(),
      };
    } else if (
      headerComponent.value.format &&
      headerComponent.value.format === 'LOCATION'
    ) {
      // Location headers need location data
      allVariables.header = {
        location: {
          latitude: '',
          longitude: '',
          name: '',
          address: '',
        },
        location_type: 'location',
      };
    }
  }

  // Process footer variables
  if (footerComponent.value?.text) {
    const footerVars = footerComponent.value.text.match(/{{([^}]+)}}/g) || [];
    if (footerVars.length > 0) {
      allVariables.footer = {};
      footerVars.forEach(variable => {
        const key = processVariable(variable);
        allVariables.footer[key] = '';
      });
    }
  }

  // Process button variables
  buttonComponents.value.forEach(buttonComponent => {
    if (buttonComponent.buttons) {
      buttonComponent.buttons.forEach((button, index) => {
        // Handle URL buttons with variables
        if (button.url && button.url.includes('{{')) {
          const buttonVars = button.url.match(/{{([^}]+)}}/g) || [];
          if (buttonVars.length > 0) {
            if (!allVariables.buttons) allVariables.buttons = [];
            allVariables.buttons[index] = {
              type: 'url',
              parameter: '',
            };
          }
        }

        // Handle copy code buttons
        if (button.type === 'COPY_CODE') {
          if (!allVariables.buttons) allVariables.buttons = [];
          allVariables.buttons[index] = {
            type: 'copy_code',
            parameter: '',
          };
        }

        // Handle interactive buttons with dynamic text
        if (['quick_reply', 'url', 'phone_number'].includes(button.type)) {
          if (button.text && button.text.includes('{{')) {
            if (!allVariables.buttons) allVariables.buttons = [];
            allVariables.buttons[index] = {
              type: button.type,
              parameter: '',
              text: button.text,
            };
          }
        }
      });
    }
  });

  // Process interactive components (LIST, PRODUCT, CATALOG)
  interactiveComponents.value.forEach(component => {
    if (component.type === 'LIST') {
      allVariables.interactive = {
        type: 'list',
        button_text: 'Select Option',
        sections: component.sections || [],
      };
    } else if (component.type === 'PRODUCT') {
      allVariables.interactive = {
        type: 'product',
        catalog_id: component.catalog_id || '',
        product_id: component.product_id || '',
      };
    } else if (component.type === 'CATALOG') {
      allVariables.interactive = {
        type: 'catalog',
        catalog_id: component.catalog_id || '',
        title: component.title || 'Browse Products',
      };
    }
  });

  processedParams.value = allVariables;
};

const validateButtonParameter = (button, index) => {
  const parameter = processedParams.value.buttons[index].parameter;

  if (button.type === 'copy_code') {
    if (parameter && parameter.length > 15) {
      processedParams.value.buttons[index].parameter = parameter.substring(
        0,
        15
      );
    }
  }
};

const getHeaderFieldLabel = key => {
  if (key === 'media_url') {
    const mediaType = processedParams.value.header?.media_type || 'media';
    return (
      t('WHATSAPP_TEMPLATES.PARSER.MEDIA_URL', {
        type: mediaType.toUpperCase(),
      }) || `${mediaType.toUpperCase()} URL`
    );
  }
  return key;
};

const getHeaderFieldPlaceholder = key => {
  if (key === 'media_url') {
    const mediaType = processedParams.value.header?.media_type || 'media';
    switch (mediaType) {
      case 'image':
        return (
          t('WHATSAPP_TEMPLATES.PARSER.IMAGE_URL_PLACEHOLDER') ||
          'Enter image URL (https://example.com/image.jpg)'
        );
      case 'video':
        return (
          t('WHATSAPP_TEMPLATES.PARSER.VIDEO_URL_PLACEHOLDER') ||
          'Enter video URL (https://example.com/video.mp4)'
        );
      case 'document':
        return (
          t('WHATSAPP_TEMPLATES.PARSER.DOCUMENT_URL_PLACEHOLDER') ||
          'Enter document URL (https://example.com/document.pdf)'
        );
      default:
        return 'Enter media URL';
    }
  }
  return `Enter ${key} value`;
};

const getBodyParameterLabel = key => {
  if (props.template?.category === 'AUTHENTICATION') {
    switch (key) {
      case 'otp_code':
        return t('WHATSAPP_TEMPLATES.PARSER.OTP_CODE') || 'OTP Code';
      case 'expiry_minutes':
        return (
          t('WHATSAPP_TEMPLATES.PARSER.EXPIRY_MINUTES') || 'Expiry (minutes)'
        );
      default:
        return key;
    }
  }
  return key;
};

const getBodyParameterPlaceholder = key => {
  if (props.template?.category === 'AUTHENTICATION') {
    switch (key) {
      case 'otp_code':
        return (
          t('WHATSAPP_TEMPLATES.PARSER.OTP_CODE_PLACEHOLDER') ||
          'Enter 4-8 digit OTP code'
        );
      case 'expiry_minutes':
        return (
          t('WHATSAPP_TEMPLATES.PARSER.EXPIRY_MINUTES_PLACEHOLDER') ||
          'Enter expiry time in minutes'
        );
      default:
        return `Enter ${key} value`;
    }
  }
  return `Enter ${key} value`;
};

const getBodyParameterType = key => {
  if (props.template?.category === 'AUTHENTICATION') {
    switch (key) {
      case 'otp_code':
        return 'tel';
      case 'expiry_minutes':
        return 'number';
      default:
        return 'text';
    }
  }
  return 'text';
};

const getBodyParameterMaxLength = key => {
  if (props.template?.category === 'AUTHENTICATION') {
    switch (key) {
      case 'otp_code':
        return 8;
      case 'expiry_minutes':
        return 3;
      default:
        return null;
    }
  }
  return null;
};

const sendMessage = async () => {
  const isValid = await v$.value.$validate();
  if (!isValid) return;

  const payload = {
    message: processedString.value,
    templateParams: {
      name: props.template.name,
      category: props.template.category,
      language: props.template.language,
      namespace: props.template.namespace,
      processed_params: processedParams.value,
    },
  };
  emit('sendMessage', payload);
};

onMounted(() => {
  generateVariables();
});
</script>

<template>
  <div
    class="absolute top-full mt-1.5 max-h-[30rem] overflow-y-auto left-0 flex flex-col gap-4 px-4 pt-6 pb-5 items-start w-[28.75rem] h-auto bg-n-solid-2 border border-n-strong shadow-sm rounded-lg"
  >
    <span class="text-sm text-n-slate-12">
      {{
        t(
          'COMPOSE_NEW_CONVERSATION.FORM.WHATSAPP_OPTIONS.TEMPLATE_PARSER.TEMPLATE_NAME',
          { templateName: templateName }
        )
      }}
    </span>

    <p
      v-dompurify-html="processedStringWithVariableHighlight"
      class="mb-0 text-sm text-n-slate-11"
    />

    <span
      v-if="Object.keys(processedParams).length"
      class="text-sm font-medium text-n-slate-12"
    >
      {{
        t(
          'COMPOSE_NEW_CONVERSATION.FORM.WHATSAPP_OPTIONS.TEMPLATE_PARSER.VARIABLES'
        )
      }}
    </span>

    <!-- Header Variables -->
    <div v-if="processedParams.header" class="w-full">
      <h4 class="mb-2 text-sm font-medium text-n-slate-12">
        {{
          t('WHATSAPP_TEMPLATES.PARSER.HEADER_PARAMETERS') ||
          'Header Parameters'
        }}
      </h4>
      <!-- Location Parameters -->
      <div
        v-if="processedParams.header.location_type === 'location'"
        class="p-3 mb-4 space-y-3 w-full rounded-lg border bg-n-solid-1 border-n-weak"
      >
        <div class="flex gap-2 items-center mb-2">
          <div
            class="flex justify-center items-center w-4 h-4 bg-blue-500 rounded-full"
          >
            <div class="w-2 h-2 bg-white rounded-full"></div>
          </div>
          <span class="text-sm font-medium text-n-slate-12"
            >Location Details</span
          >
        </div>

        <div class="grid grid-cols-2 gap-2">
          <div>
            <label class="block mb-1 text-xs font-medium text-n-slate-10">
              📍 Latitude <span class="text-red-500">*</span>
            </label>
            <Input
              v-model="processedParams.header.location.latitude"
              custom-input-class="!h-8 w-full !bg-transparent"
              class="w-full"
              type="number"
              step="any"
              placeholder="37.7749 (San Francisco)"
              :message-type="getFieldErrorType('header.location.latitude')"
            />
            <span class="text-xs text-n-slate-9">Range: -90.0 to 90.0</span>
          </div>
          <div>
            <label class="block mb-1 text-xs font-medium text-n-slate-10">
              📍 Longitude <span class="text-red-500">*</span>
            </label>
            <Input
              v-model="processedParams.header.location.longitude"
              custom-input-class="!h-8 w-full !bg-transparent"
              class="w-full"
              type="number"
              step="any"
              placeholder="-122.4194 (San Francisco)"
              :message-type="getFieldErrorType('header.location.longitude')"
            />
            <span class="text-xs text-n-slate-9">Range: -180.0 to 180.0</span>
          </div>
        </div>

        <div>
          <label class="block mb-1 text-xs font-medium text-n-slate-10">
            🏢 Location Name
          </label>
          <Input
            v-model="processedParams.header.location.name"
            custom-input-class="!h-8 w-full !bg-transparent"
            class="w-full"
            placeholder="Your Business Name"
            :message-type="getFieldErrorType('header.location.name')"
          />
        </div>

        <div>
          <label class="block mb-1 text-xs font-medium text-n-slate-10">
            📮 Full Address
          </label>
          <Input
            v-model="processedParams.header.location.address"
            custom-input-class="!h-8 w-full !bg-transparent"
            class="w-full"
            placeholder="123 Main Street, City, State 12345"
            :message-type="getFieldErrorType('header.location.address')"
          />
        </div>

        <div
          class="p-2 text-xs bg-blue-50 rounded border-l-4 border-blue-400 text-n-slate-9"
        >
          💡 <strong>Tip:</strong> You can get coordinates by searching your
          location on Google Maps, right-clicking the pin, and copying the
          latitude/longitude values.
        </div>
      </div>

      <!-- Regular Header Parameters -->
      <div v-if="processedParams.header.location_type !== 'location'">
        <div
          v-for="(variable, key) in processedParams.header"
          v-if="!['location', 'location_type'].includes(key)"
          :key="`header-${key}`"
          class="flex gap-2 items-center mb-2 w-full"
        >
          <span
            class="flex items-center h-8 text-sm min-w-6 ltr:text-left rtl:text-right text-n-slate-10"
          >
            {{ getHeaderFieldLabel(key) }}
          </span>
          <Input
            v-model="processedParams.header[key]"
            custom-input-class="!h-8 w-full !bg-transparent"
            class="w-full"
            :message-type="getFieldErrorType(`header.${key}`)"
            :placeholder="getHeaderFieldPlaceholder(key)"
            :type="key === 'media_url' ? 'url' : 'text'"
          />
        </div>
      </div>
    </div>

    <!-- Body Variables -->
    <div v-if="processedParams.body" class="w-full">
      <h4 class="mb-2 text-sm font-medium text-n-slate-12">
        {{
          t('WHATSAPP_TEMPLATES.PARSER.BODY_PARAMETERS') || 'Body Parameters'
        }}
      </h4>
      <div
        v-for="(variable, key) in processedParams.body"
        :key="`body-${key}`"
        class="flex gap-2 items-center mb-2 w-full"
      >
        <span
          class="flex items-center h-8 text-sm min-w-6 ltr:text-left rtl:text-right text-n-slate-10"
        >
          {{ getBodyParameterLabel(key) }}
        </span>
        <Input
          v-model="processedParams.body[key]"
          custom-input-class="!h-8 w-full !bg-transparent"
          class="w-full"
          :message-type="getFieldErrorType(`body.${key}`)"
          :placeholder="getBodyParameterPlaceholder(key)"
          :type="getBodyParameterType(key)"
          :maxlength="getBodyParameterMaxLength(key)"
        />
      </div>
    </div>

    <!-- Footer Variables -->
    <div v-if="processedParams.footer" class="w-full">
      <h4 class="mb-2 text-sm font-medium text-n-slate-12">
        {{
          t('WHATSAPP_TEMPLATES.PARSER.FOOTER_PARAMETERS') ||
          'Footer Parameters'
        }}
      </h4>
      <div
        v-for="(variable, key) in processedParams.footer"
        :key="`footer-${key}`"
        class="flex gap-2 items-center mb-2 w-full"
      >
        <span
          class="flex items-center h-8 text-sm min-w-6 ltr:text-left rtl:text-right text-n-slate-10"
        >
          {{ key }}
        </span>
        <Input
          v-model="processedParams.footer[key]"
          custom-input-class="!h-8 w-full !bg-transparent"
          class="w-full"
          :message-type="getFieldErrorType(`footer.${key}`)"
        />
      </div>
    </div>

    <!-- Interactive Components -->
    <div v-if="processedParams.interactive" class="w-full">
      <h4 class="mb-2 text-sm font-medium text-n-slate-12">
        {{
          t('WHATSAPP_TEMPLATES.PARSER.INTERACTIVE_PARAMETERS') ||
          'Interactive Parameters'
        }}
      </h4>

      <!-- Product Template -->
      <div
        v-if="processedParams.interactive.type === 'product'"
        class="mb-4 space-y-2"
      >
        <div>
          <label class="block mb-1 text-xs font-medium text-n-slate-10"
            >Catalog ID</label
          >
          <Input
            v-model="processedParams.interactive.catalog_id"
            custom-input-class="!h-8 w-full !bg-transparent"
            class="w-full"
            placeholder="Enter catalog ID"
            :message-type="getFieldErrorType('interactive.catalog_id')"
          />
        </div>
        <div>
          <label class="block mb-1 text-xs font-medium text-n-slate-10"
            >Product ID</label
          >
          <Input
            v-model="processedParams.interactive.product_id"
            custom-input-class="!h-8 w-full !bg-transparent"
            class="w-full"
            placeholder="Enter product retailer ID"
            :message-type="getFieldErrorType('interactive.product_id')"
          />
        </div>
      </div>

      <!-- Catalog Template -->
      <div
        v-else-if="processedParams.interactive.type === 'catalog'"
        class="mb-4 space-y-2"
      >
        <div>
          <label class="block mb-1 text-xs font-medium text-n-slate-10"
            >Catalog ID</label
          >
          <Input
            v-model="processedParams.interactive.catalog_id"
            custom-input-class="!h-8 w-full !bg-transparent"
            class="w-full"
            placeholder="Enter catalog ID"
            :message-type="getFieldErrorType('interactive.catalog_id')"
          />
        </div>
        <div>
          <label class="block mb-1 text-xs font-medium text-n-slate-10"
            >Browse Title</label
          >
          <Input
            v-model="processedParams.interactive.title"
            custom-input-class="!h-8 w-full !bg-transparent"
            class="w-full"
            placeholder="Browse Products"
            :message-type="getFieldErrorType('interactive.title')"
          />
        </div>
      </div>

      <!-- List Template -->
      <div
        v-else-if="processedParams.interactive.type === 'list'"
        class="mb-4 space-y-2"
      >
        <div>
          <label class="block mb-1 text-xs font-medium text-n-slate-10"
            >Button Text</label
          >
          <Input
            v-model="processedParams.interactive.button_text"
            custom-input-class="!h-8 w-full !bg-transparent"
            class="w-full"
            placeholder="Select an Option"
            :message-type="getFieldErrorType('interactive.button_text')"
          />
        </div>
        <div class="text-xs text-n-slate-10">
          List sections are configured in the template and cannot be modified
          here.
        </div>
      </div>
    </div>

    <!-- Button Variables -->
    <div v-if="processedParams.buttons" class="w-full">
      <h4 class="mb-2 text-sm font-medium text-n-slate-12">
        {{
          t('WHATSAPP_TEMPLATES.PARSER.BUTTON_PARAMETERS') ||
          'Button Parameters'
        }}
      </h4>
      <div
        v-for="(button, index) in processedParams.buttons"
        :key="`button-${index}`"
        class="flex gap-2 items-center mb-2 w-full"
      >
        <span
          class="flex items-center h-8 text-sm min-w-6 ltr:text-left rtl:text-right text-n-slate-10"
        >
          {{
            button.type === 'copy_code'
              ? t('WHATSAPP_TEMPLATES.PARSER.COUPON_CODE') || 'Coupon Code'
              : `${t('WHATSAPP_TEMPLATES.PARSER.BUTTON') || 'Button'} ${index + 1}`
          }}
        </span>
        <Input
          v-model="processedParams.buttons[index].parameter"
          custom-input-class="!h-8 w-full !bg-transparent"
          class="w-full"
          :message-type="getFieldErrorType(`buttons.${index}.parameter`)"
          :placeholder="
            button.type === 'copy_code'
              ? 'Enter coupon code (max 15 chars)'
              : 'Enter button parameter'
          "
          :max-length="button.type === 'copy_code' ? 15 : 500"
          @input="validateButtonParameter(button, index)"
        />
      </div>
    </div>

    <!-- Legacy Variables (for backward compatibility) -->
    <div
      v-for="(variable, key) in legacyParams"
      :key="key"
      class="flex gap-2 items-center w-full"
    >
      <span
        class="flex items-center h-8 text-sm min-w-6 ltr:text-left rtl:text-right text-n-slate-10"
      >
        {{ key }}
      </span>
      <Input
        v-model="processedParams[key]"
        custom-input-class="!h-8 w-full !bg-transparent"
        class="w-full"
        :message-type="getFieldErrorType(key)"
      />
    </div>

    <div class="flex gap-3 justify-between items-end w-full h-14">
      <Button
        :label="
          t(
            'COMPOSE_NEW_CONVERSATION.FORM.WHATSAPP_OPTIONS.TEMPLATE_PARSER.BACK'
          )
        "
        color="slate"
        variant="faded"
        class="w-full font-medium"
        @click="emit('back')"
      />
      <Button
        :label="
          t(
            'COMPOSE_NEW_CONVERSATION.FORM.WHATSAPP_OPTIONS.TEMPLATE_PARSER.SEND_MESSAGE'
          )
        "
        class="w-full font-medium"
        @click="sendMessage"
      />
    </div>
  </div>
</template>
