import { defineComponent, computed, onMounted, ref, resolveDirective, openBlock, createElementBlock, createElementVNode, createVNode, unref, isRef, withKeys, withCtx, withDirectives, withModifiers, vModelText, toDisplayString, createBlock, createCommentVNode, normalizeClass, nextTick } from "@histoire/vendors/vue";
import { Icon } from "@histoire/vendors/iconify";
import { useStorage, useTimeoutFn, onClickOutside } from "@histoire/vendors/vue-use";
import { clone, omit, applyState } from "@histoire/shared";
import "../base/BaseSelect.vue.js";
import { toRawDeep } from "../../util/state.js";
import _sfc_main$1 from "../base/BaseSelect.vue2.js";
"use strict";
const _hoisted_1 = { class: "histoire-state-presets htw-flex htw-gap-2 htw-w-full htw-items-center" };
const _hoisted_2 = ["onUpdate:modelValue"];
const _hoisted_3 = {
  key: 1,
  class: "htw-flex htw-items-center htw-gap-2"
};
const _hoisted_4 = { class: "htw-flex-1 htw-truncate" };
const _hoisted_5 = { class: "htw-flex htw-gap-2 htw-items-center" };
const _hoisted_6 = { class: "htw-flex-1 htw-truncate" };
const DEFAULT_ID = "default";
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "StatePresets",
  props: {
    story: {},
    variant: {}
  },
  setup(__props) {
    const props = __props;
    const saveId = computed(() => `${props.story.id}:${props.variant.id}`);
    const omitKeys = ["_hPropDefs"];
    const defaultState = clone(omit(toRawDeep(props.variant.state), omitKeys));
    const selectedOption = useStorage(
      `_histoire-presets/${saveId.value}/selected`,
      DEFAULT_ID
    );
    const presetStates = useStorage(
      `_histoire-presets/${saveId.value}/states`,
      /* @__PURE__ */ new Map()
    );
    const presetsOptions = computed(() => {
      const options = { [DEFAULT_ID]: "Initial state" };
      presetStates.value.forEach((value, key) => {
        options[key] = value.label;
      });
      return options;
    });
    function resetState() {
      selectedOption.value = DEFAULT_ID;
      applyState(props.variant.state, clone(defaultState));
    }
    function applyPreset(id) {
      if (id === DEFAULT_ID) {
        resetState();
      } else if (presetStates.value.has(id)) {
        applyState(props.variant.state, clone(toRawDeep(presetStates.value.get(id).state)));
      }
    }
    onMounted(() => {
      if (selectedOption.value !== DEFAULT_ID) {
        applyPreset(selectedOption.value);
      }
    });
    const input = ref();
    const select = ref();
    const canEdit = computed(() => selectedOption.value !== DEFAULT_ID);
    const isEditing = ref(false);
    async function createPreset() {
      const id = (/* @__PURE__ */ new Date()).getTime().toString();
      presetStates.value.set(id, { state: clone(omit(toRawDeep(props.variant.state), omitKeys)), label: "New preset" });
      selectedOption.value = id;
      isEditing.value = true;
      await nextTick();
      input.value.select();
    }
    const savedNotif = ref(false);
    const savedTimeout = useTimeoutFn(() => {
      savedNotif.value = false;
    }, 1e3);
    async function savePreset() {
      if (!canEdit.value)
        return;
      const preset = presetStates.value.get(selectedOption.value);
      preset.state = clone(omit(toRawDeep(props.variant.state), omitKeys));
      savedNotif.value = true;
      savedTimeout.start();
    }
    function deletePreset(id) {
      if (!confirm("Are you sure you want to delete this preset?")) {
        return;
      }
      if (selectedOption.value === id) {
        resetState();
      }
      presetStates.value.delete(id);
    }
    async function startEditing() {
      if (!canEdit.value) {
        return;
      }
      isEditing.value = true;
      await nextTick();
      input.value.select();
    }
    function stopEditing() {
      isEditing.value = false;
    }
    onClickOutside(select, stopEditing);
    return (_ctx, _cache) => {
      const _directive_tooltip = resolveDirective("tooltip");
      return openBlock(), createElementBlock("div", _hoisted_1, [
        createElementVNode("div", {
          ref_key: "select",
          ref: select,
          class: "htw-flex-1 htw-min-w-0"
        }, [
          createVNode(_sfc_main$1, {
            modelValue: unref(selectedOption),
            "onUpdate:modelValue": _cache[2] || (_cache[2] = ($event) => isRef(selectedOption) ? selectedOption.value = $event : null),
            options: presetsOptions.value,
            onDblclick: _cache[3] || (_cache[3] = ($event) => startEditing()),
            onKeydown: [
              _cache[4] || (_cache[4] = withKeys(($event) => stopEditing(), ["enter"])),
              _cache[5] || (_cache[5] = withKeys(($event) => stopEditing(), ["escape"]))
            ],
            onSelect: _cache[6] || (_cache[6] = (id) => applyPreset(id))
          }, {
            default: withCtx(({ label }) => [
              isEditing.value ? withDirectives((openBlock(), createElementBlock("input", {
                key: 0,
                ref_key: "input",
                ref: input,
                "onUpdate:modelValue": ($event) => unref(presetStates).get(unref(selectedOption)).label = $event,
                type: "text",
                class: "htw-text-inherit htw-bg-transparent htw-w-full htw-h-full htw-outline-none",
                onClick: _cache[0] || (_cache[0] = withModifiers(() => {
                }, ["stop", "prevent"]))
              }, null, 8, _hoisted_2)), [
                [vModelText, unref(presetStates).get(unref(selectedOption)).label]
              ]) : (openBlock(), createElementBlock("div", _hoisted_3, [
                createElementVNode("span", _hoisted_4, toDisplayString(label), 1),
                canEdit.value ? withDirectives((openBlock(), createBlock(unref(Icon), {
                  key: 0,
                  icon: "carbon:edit",
                  class: "htw-flex-none htw-cursor-pointer htw-w-4 htw-h-4 hover:htw-text-primary-500 htw-opacity-50 hover:htw-opacity-100 dark:hover:htw-text-primary-400 htw-text-gray-900 dark:htw-text-gray-100",
                  onClick: _cache[1] || (_cache[1] = withModifiers(($event) => startEditing(), ["stop"]))
                }, null, 512)), [
                  [_directive_tooltip, "Rename this preset"]
                ]) : createCommentVNode("", true)
              ]))
            ]),
            option: withCtx(({ label, value }) => [
              createElementVNode("div", _hoisted_5, [
                createElementVNode("span", _hoisted_6, toDisplayString(label), 1),
                value !== DEFAULT_ID ? withDirectives((openBlock(), createBlock(unref(Icon), {
                  key: 0,
                  icon: "carbon:trash-can",
                  class: "htw-flex-none htw-cursor-pointer htw-w-4 htw-h-4 hover:htw-text-primary-500 htw-opacity-50 hover:htw-opacity-100 dark:hover:htw-text-primary-400 htw-text-gray-900 dark:htw-text-gray-100",
                  onClick: withModifiers(($event) => deletePreset(value), ["stop"])
                }, null, 8, ["onClick"])), [
                  [_directive_tooltip, "Delete this preset"]
                ]) : createCommentVNode("", true)
              ])
            ]),
            _: 1
          }, 8, ["modelValue", "options"])
        ], 512),
        withDirectives(createVNode(unref(Icon), {
          icon: savedNotif.value ? "carbon:checkmark" : "carbon:save",
          class: normalizeClass(["htw-cursor-pointer htw-w-4 htw-h-4 hover:htw-text-primary-500 dark:hover:htw-text-primary-400 htw-text-gray-900 dark:htw-text-gray-100", [
            canEdit.value ? "htw-opacity-50 hover:htw-opacity-100" : "htw-opacity-25 htw-pointer-events-none"
          ]]),
          onClick: _cache[7] || (_cache[7] = ($event) => savePreset())
        }, null, 8, ["icon", "class"]), [
          [_directive_tooltip, savedNotif.value ? "Saved!" : canEdit.value ? "Save to preset" : null]
        ]),
        withDirectives(createVNode(unref(Icon), {
          icon: "carbon:add-alt",
          class: "htw-cursor-pointer htw-w-4 htw-h-4 hover:htw-text-primary-500 htw-opacity-50 hover:htw-opacity-100 dark:hover:htw-text-primary-400 htw-text-gray-900 dark:htw-text-gray-100",
          onClick: _cache[8] || (_cache[8] = ($event) => createPreset())
        }, null, 512), [
          [_directive_tooltip, "Create new preset"]
        ]),
        withDirectives(createVNode(unref(Icon), {
          icon: "carbon:reset",
          class: "htw-cursor-pointer htw-w-4 htw-h-4 hover:htw-text-primary-500 htw-opacity-50 hover:htw-opacity-100 dark:hover:htw-text-primary-400 htw-text-gray-900 dark:htw-text-gray-100",
          onClick: _cache[9] || (_cache[9] = ($event) => resetState())
        }, null, 512), [
          [_directive_tooltip, "Reset to initial state"]
        ])
      ]);
    };
  }
});
export {
  _sfc_main as default
};
