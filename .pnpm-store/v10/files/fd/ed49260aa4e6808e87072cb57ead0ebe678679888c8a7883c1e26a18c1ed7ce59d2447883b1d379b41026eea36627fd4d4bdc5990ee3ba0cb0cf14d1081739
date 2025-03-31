/* eslint-disable vue/one-component-per-file */
import { defineComponent as _defineComponent, onBeforeUnmount as _onBeforeUnmount, onMounted as _onMounted, ref as _ref, watch as _watch, h as _h, } from '@histoire/vendors/vue';
// @ts-expect-error virtual module id
import * as setup from 'virtual:$histoire-setup';
// @ts-expect-error virtual module id
import * as generatedSetup from 'virtual:$histoire-generated-global-setup';
export default _defineComponent({
    name: 'RenderStory',
    props: {
        variant: {
            type: Object,
            required: true,
        },
        story: {
            type: Object,
            required: true,
        },
        slotName: {
            type: String,
            default: 'default',
        },
    },
    emits: {
        ready: () => true,
    },
    setup(props, { emit }) {
        const sandbox = _ref();
        let mounting = false;
        let app;
        let appHooks;
        async function unmountVariant() {
            if (app) {
                await app.onUnmount?.();
                if (appHooks) {
                    for (const hook of appHooks.onUnmount) {
                        await hook();
                    }
                }
                app.el.parentNode.removeChild(app.el);
                app = null;
            }
        }
        async function mountVariant() {
            if (mounting)
                return;
            mounting = true;
            await unmountVariant();
            app = {
                el: document.createElement('div'),
            };
            if (typeof generatedSetup?.setupVanilla === 'function') {
                await generatedSetup.setupVanilla({
                    app,
                    story: props.story,
                    variant: props.variant,
                });
            }
            if (typeof setup?.setupVanilla === 'function') {
                await setup.setupVanilla({
                    app,
                    story: props.story,
                    variant: props.variant,
                });
            }
            if (typeof props.variant.setupApp === 'function') {
                await props.variant.setupApp({
                    app,
                    story: props.story,
                    variant: props.variant,
                });
            }
            await app.onMount?.();
            appHooks = {
                onUpdate: [],
                onUnmount: [],
            };
            const api = {
                el: app.el,
                state: props.variant.state,
                onUpdate: (cb) => {
                    appHooks.onUpdate.push(cb);
                },
                onUnmount: (cb) => {
                    appHooks.onUnmount.push(cb);
                },
            };
            const onMount = props.variant.slots()[props.slotName];
            await onMount(api);
            sandbox.value.appendChild(app.el);
            emit('ready');
        }
        _onMounted(async () => {
            if (props.variant.configReady) {
                await mountVariant();
            }
        });
        _watch(() => props.variant, async (value) => {
            if (value.configReady && !mounting) {
                if (!app) {
                    await mountVariant();
                }
                else {
                    // @TODO check if need to refresh here
                }
            }
        }, {
            deep: true,
        });
        _watch(() => props.variant.state, async () => {
            if (appHooks) {
                for (const hook of appHooks.onUpdate) {
                    await hook();
                }
            }
        }, {
            deep: true,
        });
        _onBeforeUnmount(() => {
            unmountVariant();
        });
        return {
            sandbox,
        };
    },
    render() {
        return _h('div', {
            ref: 'sandbox',
        });
    },
});
