'use strict';

Object.defineProperty(exports, '__esModule', { value: true });

var compilerDom = require('@vue/compiler-dom');
var shared = require('@vue/shared');

const SSR_INTERPOLATE = Symbol(`ssrInterpolate`);
const SSR_RENDER_VNODE = Symbol(`ssrRenderVNode`);
const SSR_RENDER_COMPONENT = Symbol(`ssrRenderComponent`);
const SSR_RENDER_SLOT = Symbol(`ssrRenderSlot`);
const SSR_RENDER_SLOT_INNER = Symbol(`ssrRenderSlotInner`);
const SSR_RENDER_CLASS = Symbol(`ssrRenderClass`);
const SSR_RENDER_STYLE = Symbol(`ssrRenderStyle`);
const SSR_RENDER_ATTRS = Symbol(`ssrRenderAttrs`);
const SSR_RENDER_ATTR = Symbol(`ssrRenderAttr`);
const SSR_RENDER_DYNAMIC_ATTR = Symbol(`ssrRenderDynamicAttr`);
const SSR_RENDER_LIST = Symbol(`ssrRenderList`);
const SSR_INCLUDE_BOOLEAN_ATTR = Symbol(`ssrIncludeBooleanAttr`);
const SSR_LOOSE_EQUAL = Symbol(`ssrLooseEqual`);
const SSR_LOOSE_CONTAIN = Symbol(`ssrLooseContain`);
const SSR_RENDER_DYNAMIC_MODEL = Symbol(`ssrRenderDynamicModel`);
const SSR_GET_DYNAMIC_MODEL_PROPS = Symbol(`ssrGetDynamicModelProps`);
const SSR_RENDER_TELEPORT = Symbol(`ssrRenderTeleport`);
const SSR_RENDER_SUSPENSE = Symbol(`ssrRenderSuspense`);
const SSR_GET_DIRECTIVE_PROPS = Symbol(`ssrGetDirectiveProps`);
const ssrHelpers = {
    [SSR_INTERPOLATE]: `ssrInterpolate`,
    [SSR_RENDER_VNODE]: `ssrRenderVNode`,
    [SSR_RENDER_COMPONENT]: `ssrRenderComponent`,
    [SSR_RENDER_SLOT]: `ssrRenderSlot`,
    [SSR_RENDER_SLOT_INNER]: `ssrRenderSlotInner`,
    [SSR_RENDER_CLASS]: `ssrRenderClass`,
    [SSR_RENDER_STYLE]: `ssrRenderStyle`,
    [SSR_RENDER_ATTRS]: `ssrRenderAttrs`,
    [SSR_RENDER_ATTR]: `ssrRenderAttr`,
    [SSR_RENDER_DYNAMIC_ATTR]: `ssrRenderDynamicAttr`,
    [SSR_RENDER_LIST]: `ssrRenderList`,
    [SSR_INCLUDE_BOOLEAN_ATTR]: `ssrIncludeBooleanAttr`,
    [SSR_LOOSE_EQUAL]: `ssrLooseEqual`,
    [SSR_LOOSE_CONTAIN]: `ssrLooseContain`,
    [SSR_RENDER_DYNAMIC_MODEL]: `ssrRenderDynamicModel`,
    [SSR_GET_DYNAMIC_MODEL_PROPS]: `ssrGetDynamicModelProps`,
    [SSR_RENDER_TELEPORT]: `ssrRenderTeleport`,
    [SSR_RENDER_SUSPENSE]: `ssrRenderSuspense`,
    [SSR_GET_DIRECTIVE_PROPS]: `ssrGetDirectiveProps`
};
// Note: these are helpers imported from @vue/server-renderer
// make sure the names match!
compilerDom.registerRuntimeHelpers(ssrHelpers);

// Plugin for the first transform pass, which simply constructs the AST node
const ssrTransformIf = compilerDom.createStructuralDirectiveTransform(/^(if|else|else-if)$/, compilerDom.processIf);
// This is called during the 2nd transform pass to construct the SSR-specific
// codegen nodes.
function ssrProcessIf(node, context, disableNestedFragments = false) {
    const [rootBranch] = node.branches;
    const ifStatement = compilerDom.createIfStatement(rootBranch.condition, processIfBranch(rootBranch, context, disableNestedFragments));
    context.pushStatement(ifStatement);
    let currentIf = ifStatement;
    for (let i = 1; i < node.branches.length; i++) {
        const branch = node.branches[i];
        const branchBlockStatement = processIfBranch(branch, context, disableNestedFragments);
        if (branch.condition) {
            // else-if
            currentIf = currentIf.alternate = compilerDom.createIfStatement(branch.condition, branchBlockStatement);
        }
        else {
            // else
            currentIf.alternate = branchBlockStatement;
        }
    }
    if (!currentIf.alternate) {
        currentIf.alternate = compilerDom.createBlockStatement([
            compilerDom.createCallExpression(`_push`, ['`<!---->`'])
        ]);
    }
}
function processIfBranch(branch, context, disableNestedFragments = false) {
    const { children } = branch;
    const needFragmentWrapper = !disableNestedFragments &&
        (children.length !== 1 || children[0].type !== 1 /* ELEMENT */) &&
        // optimize away nested fragments when the only child is a ForNode
        !(children.length === 1 && children[0].type === 11 /* FOR */);
    return processChildrenAsStatement(branch, context, needFragmentWrapper);
}

// Plugin for the first transform pass, which simply constructs the AST node
const ssrTransformFor = compilerDom.createStructuralDirectiveTransform('for', compilerDom.processFor);
// This is called during the 2nd transform pass to construct the SSR-specific
// codegen nodes.
function ssrProcessFor(node, context, disableNestedFragments = false) {
    const needFragmentWrapper = !disableNestedFragments &&
        (node.children.length !== 1 || node.children[0].type !== 1 /* ELEMENT */);
    const renderLoop = compilerDom.createFunctionExpression(compilerDom.createForLoopParams(node.parseResult));
    renderLoop.body = processChildrenAsStatement(node, context, needFragmentWrapper);
    // v-for always renders a fragment unless explicitly disabled
    if (!disableNestedFragments) {
        context.pushStringPart(`<!--[-->`);
    }
    context.pushStatement(compilerDom.createCallExpression(context.helper(SSR_RENDER_LIST), [
        node.source,
        renderLoop
    ]));
    if (!disableNestedFragments) {
        context.pushStringPart(`<!--]-->`);
    }
}

const ssrTransformSlotOutlet = (node, context) => {
    if (compilerDom.isSlotOutlet(node)) {
        const { slotName, slotProps } = compilerDom.processSlotOutlet(node, context);
        const args = [
            `_ctx.$slots`,
            slotName,
            slotProps || `{}`,
            // fallback content placeholder. will be replaced in the process phase
            `null`,
            `_push`,
            `_parent`
        ];
        // inject slot scope id if current template uses :slotted
        if (context.scopeId && context.slotted !== false) {
            args.push(`"${context.scopeId}-s"`);
        }
        let method = SSR_RENDER_SLOT;
        // #3989
        // check if this is a single slot inside a transition wrapper - since
        // transition will unwrap the slot fragment into a single vnode at runtime,
        // we need to avoid rendering the slot as a fragment.
        const parent = context.parent;
        if (parent &&
            parent.type === 1 /* ELEMENT */ &&
            parent.tagType === 1 /* COMPONENT */ &&
            compilerDom.resolveComponentType(parent, context, true) === compilerDom.TRANSITION &&
            parent.children.filter(c => c.type === 1 /* ELEMENT */).length === 1) {
            method = SSR_RENDER_SLOT_INNER;
            if (!(context.scopeId && context.slotted !== false)) {
                args.push('null');
            }
            args.push('true');
        }
        node.ssrCodegenNode = compilerDom.createCallExpression(context.helper(method), args);
    }
};
function ssrProcessSlotOutlet(node, context) {
    const renderCall = node.ssrCodegenNode;
    // has fallback content
    if (node.children.length) {
        const fallbackRenderFn = compilerDom.createFunctionExpression([]);
        fallbackRenderFn.body = processChildrenAsStatement(node, context);
        // _renderSlot(slots, name, props, fallback, ...)
        renderCall.arguments[3] = fallbackRenderFn;
    }
    // Forwarded <slot/>. Merge slot scope ids
    if (context.withSlotScopeId) {
        const slotScopeId = renderCall.arguments[6];
        renderCall.arguments[6] = slotScopeId
            ? `${slotScopeId} + _scopeId`
            : `_scopeId`;
    }
    context.pushStatement(node.ssrCodegenNode);
}

function createSSRCompilerError(code, loc) {
    return compilerDom.createCompilerError(code, loc, SSRErrorMessages);
}
const SSRErrorMessages = {
    [61 /* X_SSR_UNSAFE_ATTR_NAME */]: `Unsafe attribute name for SSR.`,
    [62 /* X_SSR_NO_TELEPORT_TARGET */]: `Missing the 'to' prop on teleport element.`,
    [63 /* X_SSR_INVALID_AST_NODE */]: `Invalid AST node during SSR transform.`
};

// Note: this is a 2nd-pass codegen transform.
function ssrProcessTeleport(node, context) {
    const targetProp = compilerDom.findProp(node, 'to');
    if (!targetProp) {
        context.onError(createSSRCompilerError(62 /* X_SSR_NO_TELEPORT_TARGET */, node.loc));
        return;
    }
    let target;
    if (targetProp.type === 6 /* ATTRIBUTE */) {
        target =
            targetProp.value && compilerDom.createSimpleExpression(targetProp.value.content, true);
    }
    else {
        target = targetProp.exp;
    }
    if (!target) {
        context.onError(createSSRCompilerError(62 /* X_SSR_NO_TELEPORT_TARGET */, targetProp.loc));
        return;
    }
    const disabledProp = compilerDom.findProp(node, 'disabled', false, true /* allow empty */);
    const disabled = disabledProp
        ? disabledProp.type === 6 /* ATTRIBUTE */
            ? `true`
            : disabledProp.exp || `false`
        : `false`;
    const contentRenderFn = compilerDom.createFunctionExpression([`_push`], undefined, // Body is added later
    true, // newline
    false, // isSlot
    node.loc);
    contentRenderFn.body = processChildrenAsStatement(node, context);
    context.pushStatement(compilerDom.createCallExpression(context.helper(SSR_RENDER_TELEPORT), [
        `_push`,
        contentRenderFn,
        target,
        disabled,
        `_parent`
    ]));
}

const wipMap = new WeakMap();
// phase 1
function ssrTransformSuspense(node, context) {
    return () => {
        if (node.children.length) {
            const wipEntry = {
                slotsExp: null,
                wipSlots: []
            };
            wipMap.set(node, wipEntry);
            wipEntry.slotsExp = compilerDom.buildSlots(node, context, (_props, children, loc) => {
                const fn = compilerDom.createFunctionExpression([], undefined, // no return, assign body later
                true, // newline
                false, // suspense slots are not treated as normal slots
                loc);
                wipEntry.wipSlots.push({
                    fn,
                    children
                });
                return fn;
            }).slots;
        }
    };
}
// phase 2
function ssrProcessSuspense(node, context) {
    // complete wip slots with ssr code
    const wipEntry = wipMap.get(node);
    if (!wipEntry) {
        return;
    }
    const { slotsExp, wipSlots } = wipEntry;
    for (let i = 0; i < wipSlots.length; i++) {
        const slot = wipSlots[i];
        slot.fn.body = processChildrenAsStatement(slot, context);
    }
    // _push(ssrRenderSuspense(slots))
    context.pushStatement(compilerDom.createCallExpression(context.helper(SSR_RENDER_SUSPENSE), [
        `_push`,
        slotsExp
    ]));
}

// for directives with children overwrite (e.g. v-html & v-text), we need to
// store the raw children so that they can be added in the 2nd pass.
const rawChildrenMap = new WeakMap();
const ssrTransformElement = (node, context) => {
    if (node.type !== 1 /* ELEMENT */ ||
        node.tagType !== 0 /* ELEMENT */) {
        return;
    }
    return function ssrPostTransformElement() {
        // element
        // generate the template literal representing the open tag.
        const openTag = [`<${node.tag}`];
        // some tags need to be passed to runtime for special checks
        const needTagForRuntime = node.tag === 'textarea' || node.tag.indexOf('-') > 0;
        // v-bind="obj", v-bind:[key] and custom directives can potentially
        // overwrite other static attrs and can affect final rendering result,
        // so when they are present we need to bail out to full `renderAttrs`
        const hasDynamicVBind = compilerDom.hasDynamicKeyVBind(node);
        const hasCustomDir = node.props.some(p => p.type === 7 /* DIRECTIVE */ && !shared.isBuiltInDirective(p.name));
        const needMergeProps = hasDynamicVBind || hasCustomDir;
        if (needMergeProps) {
            const { props, directives } = compilerDom.buildProps(node, context, node.props, false /* isComponent */, false /* isDynamicComponent */, true /* ssr */);
            if (props || directives.length) {
                const mergedProps = buildSSRProps(props, directives, context);
                const propsExp = compilerDom.createCallExpression(context.helper(SSR_RENDER_ATTRS), [mergedProps]);
                if (node.tag === 'textarea') {
                    const existingText = node.children[0];
                    // If interpolation, this is dynamic <textarea> content, potentially
                    // injected by v-model and takes higher priority than v-bind value
                    if (!existingText || existingText.type !== 5 /* INTERPOLATION */) {
                        // <textarea> with dynamic v-bind. We don't know if the final props
                        // will contain .value, so we will have to do something special:
                        // assign the merged props to a temp variable, and check whether
                        // it contains value (if yes, render is as children).
                        const tempId = `_temp${context.temps++}`;
                        propsExp.arguments = [
                            compilerDom.createAssignmentExpression(compilerDom.createSimpleExpression(tempId, false), mergedProps)
                        ];
                        rawChildrenMap.set(node, compilerDom.createCallExpression(context.helper(SSR_INTERPOLATE), [
                            compilerDom.createConditionalExpression(compilerDom.createSimpleExpression(`"value" in ${tempId}`, false), compilerDom.createSimpleExpression(`${tempId}.value`, false), compilerDom.createSimpleExpression(existingText ? existingText.content : ``, true), false)
                        ]));
                    }
                }
                else if (node.tag === 'input') {
                    // <input v-bind="obj" v-model>
                    // we need to determine the props to render for the dynamic v-model
                    // and merge it with the v-bind expression.
                    const vModel = findVModel(node);
                    if (vModel) {
                        // 1. save the props (san v-model) in a temp variable
                        const tempId = `_temp${context.temps++}`;
                        const tempExp = compilerDom.createSimpleExpression(tempId, false);
                        propsExp.arguments = [
                            compilerDom.createSequenceExpression([
                                compilerDom.createAssignmentExpression(tempExp, mergedProps),
                                compilerDom.createCallExpression(context.helper(compilerDom.MERGE_PROPS), [
                                    tempExp,
                                    compilerDom.createCallExpression(context.helper(SSR_GET_DYNAMIC_MODEL_PROPS), [
                                        tempExp,
                                        vModel.exp // model
                                    ])
                                ])
                            ])
                        ];
                    }
                }
                if (needTagForRuntime) {
                    propsExp.arguments.push(`"${node.tag}"`);
                }
                openTag.push(propsExp);
            }
        }
        // book keeping static/dynamic class merging.
        let dynamicClassBinding = undefined;
        let staticClassBinding = undefined;
        // all style bindings are converted to dynamic by transformStyle.
        // but we need to make sure to merge them.
        let dynamicStyleBinding = undefined;
        for (let i = 0; i < node.props.length; i++) {
            const prop = node.props[i];
            // ignore true-value/false-value on input
            if (node.tag === 'input' && isTrueFalseValue(prop)) {
                continue;
            }
            // special cases with children override
            if (prop.type === 7 /* DIRECTIVE */) {
                if (prop.name === 'html' && prop.exp) {
                    rawChildrenMap.set(node, prop.exp);
                }
                else if (prop.name === 'text' && prop.exp) {
                    node.children = [compilerDom.createInterpolation(prop.exp, prop.loc)];
                }
                else if (prop.name === 'slot') {
                    context.onError(compilerDom.createCompilerError(40 /* X_V_SLOT_MISPLACED */, prop.loc));
                }
                else if (isTextareaWithValue(node, prop) && prop.exp) {
                    if (!needMergeProps) {
                        node.children = [compilerDom.createInterpolation(prop.exp, prop.loc)];
                    }
                }
                else if (!needMergeProps && prop.name !== 'on') {
                    // Directive transforms.
                    const directiveTransform = context.directiveTransforms[prop.name];
                    if (directiveTransform) {
                        const { props, ssrTagParts } = directiveTransform(prop, node, context);
                        if (ssrTagParts) {
                            openTag.push(...ssrTagParts);
                        }
                        for (let j = 0; j < props.length; j++) {
                            const { key, value } = props[j];
                            if (compilerDom.isStaticExp(key)) {
                                let attrName = key.content;
                                // static key attr
                                if (attrName === 'key' || attrName === 'ref') {
                                    continue;
                                }
                                if (attrName === 'class') {
                                    openTag.push(` class="`, (dynamicClassBinding = compilerDom.createCallExpression(context.helper(SSR_RENDER_CLASS), [value])), `"`);
                                }
                                else if (attrName === 'style') {
                                    if (dynamicStyleBinding) {
                                        // already has style binding, merge into it.
                                        mergeCall(dynamicStyleBinding, value);
                                    }
                                    else {
                                        openTag.push(` style="`, (dynamicStyleBinding = compilerDom.createCallExpression(context.helper(SSR_RENDER_STYLE), [value])), `"`);
                                    }
                                }
                                else {
                                    attrName =
                                        node.tag.indexOf('-') > 0
                                            ? attrName // preserve raw name on custom elements
                                            : shared.propsToAttrMap[attrName] || attrName.toLowerCase();
                                    if (shared.isBooleanAttr(attrName)) {
                                        openTag.push(compilerDom.createConditionalExpression(compilerDom.createCallExpression(context.helper(SSR_INCLUDE_BOOLEAN_ATTR), [value]), compilerDom.createSimpleExpression(' ' + attrName, true), compilerDom.createSimpleExpression('', true), false /* no newline */));
                                    }
                                    else if (shared.isSSRSafeAttrName(attrName)) {
                                        openTag.push(compilerDom.createCallExpression(context.helper(SSR_RENDER_ATTR), [
                                            key,
                                            value
                                        ]));
                                    }
                                    else {
                                        context.onError(createSSRCompilerError(61 /* X_SSR_UNSAFE_ATTR_NAME */, key.loc));
                                    }
                                }
                            }
                            else {
                                // dynamic key attr
                                // this branch is only encountered for custom directive
                                // transforms that returns properties with dynamic keys
                                const args = [key, value];
                                if (needTagForRuntime) {
                                    args.push(`"${node.tag}"`);
                                }
                                openTag.push(compilerDom.createCallExpression(context.helper(SSR_RENDER_DYNAMIC_ATTR), args));
                            }
                        }
                    }
                }
            }
            else {
                // special case: value on <textarea>
                if (node.tag === 'textarea' && prop.name === 'value' && prop.value) {
                    rawChildrenMap.set(node, shared.escapeHtml(prop.value.content));
                }
                else if (!needMergeProps) {
                    if (prop.name === 'key' || prop.name === 'ref') {
                        continue;
                    }
                    // static prop
                    if (prop.name === 'class' && prop.value) {
                        staticClassBinding = JSON.stringify(prop.value.content);
                    }
                    openTag.push(` ${prop.name}` +
                        (prop.value ? `="${shared.escapeHtml(prop.value.content)}"` : ``));
                }
            }
        }
        // handle co-existence of dynamic + static class bindings
        if (dynamicClassBinding && staticClassBinding) {
            mergeCall(dynamicClassBinding, staticClassBinding);
            removeStaticBinding(openTag, 'class');
        }
        if (context.scopeId) {
            openTag.push(` ${context.scopeId}`);
        }
        node.ssrCodegenNode = compilerDom.createTemplateLiteral(openTag);
    };
};
function buildSSRProps(props, directives, context) {
    let mergePropsArgs = [];
    if (props) {
        if (props.type === 14 /* JS_CALL_EXPRESSION */) {
            // already a mergeProps call
            mergePropsArgs = props.arguments;
        }
        else {
            mergePropsArgs.push(props);
        }
    }
    if (directives.length) {
        for (const dir of directives) {
            mergePropsArgs.push(compilerDom.createCallExpression(context.helper(SSR_GET_DIRECTIVE_PROPS), [
                `_ctx`,
                ...compilerDom.buildDirectiveArgs(dir, context).elements
            ]));
        }
    }
    return mergePropsArgs.length > 1
        ? compilerDom.createCallExpression(context.helper(compilerDom.MERGE_PROPS), mergePropsArgs)
        : mergePropsArgs[0];
}
function isTrueFalseValue(prop) {
    if (prop.type === 7 /* DIRECTIVE */) {
        return (prop.name === 'bind' &&
            prop.arg &&
            compilerDom.isStaticExp(prop.arg) &&
            (prop.arg.content === 'true-value' || prop.arg.content === 'false-value'));
    }
    else {
        return prop.name === 'true-value' || prop.name === 'false-value';
    }
}
function isTextareaWithValue(node, prop) {
    return !!(node.tag === 'textarea' &&
        prop.name === 'bind' &&
        compilerDom.isStaticArgOf(prop.arg, 'value'));
}
function mergeCall(call, arg) {
    const existing = call.arguments[0];
    if (existing.type === 17 /* JS_ARRAY_EXPRESSION */) {
        existing.elements.push(arg);
    }
    else {
        call.arguments[0] = compilerDom.createArrayExpression([existing, arg]);
    }
}
function removeStaticBinding(tag, binding) {
    const regExp = new RegExp(`^ ${binding}=".+"$`);
    const i = tag.findIndex(e => typeof e === 'string' && regExp.test(e));
    if (i > -1) {
        tag.splice(i, 1);
    }
}
function findVModel(node) {
    return node.props.find(p => p.type === 7 /* DIRECTIVE */ && p.name === 'model' && p.exp);
}
function ssrProcessElement(node, context) {
    const isVoidTag = context.options.isVoidTag || shared.NO;
    const elementsToAdd = node.ssrCodegenNode.elements;
    for (let j = 0; j < elementsToAdd.length; j++) {
        context.pushStringPart(elementsToAdd[j]);
    }
    // Handle slot scopeId
    if (context.withSlotScopeId) {
        context.pushStringPart(compilerDom.createSimpleExpression(`_scopeId`, false));
    }
    // close open tag
    context.pushStringPart(`>`);
    const rawChildren = rawChildrenMap.get(node);
    if (rawChildren) {
        context.pushStringPart(rawChildren);
    }
    else if (node.children.length) {
        processChildren(node, context);
    }
    if (!isVoidTag(node.tag)) {
        // push closing tag
        context.pushStringPart(`</${node.tag}>`);
    }
}

const wipMap$1 = new WeakMap();
// phase 1: build props
function ssrTransformTransitionGroup(node, context) {
    return () => {
        const tag = compilerDom.findProp(node, 'tag');
        if (tag) {
            const otherProps = node.props.filter(p => p !== tag);
            const { props, directives } = compilerDom.buildProps(node, context, otherProps, true, /* isComponent */ false, /* isDynamicComponent */ true /* ssr (skip event listeners) */);
            let propsExp = null;
            if (props || directives.length) {
                propsExp = compilerDom.createCallExpression(context.helper(SSR_RENDER_ATTRS), [
                    buildSSRProps(props, directives, context)
                ]);
            }
            wipMap$1.set(node, {
                tag,
                propsExp
            });
        }
    };
}
// phase 2: process children
function ssrProcessTransitionGroup(node, context) {
    const entry = wipMap$1.get(node);
    if (entry) {
        const { tag, propsExp } = entry;
        if (tag.type === 7 /* DIRECTIVE */) {
            // dynamic :tag
            context.pushStringPart(`<`);
            context.pushStringPart(tag.exp);
            if (propsExp) {
                context.pushStringPart(propsExp);
            }
            context.pushStringPart(`>`);
            processChildren(node, context, false, 
            /**
             * TransitionGroup has the special runtime behavior of flattening and
             * concatenating all children into a single fragment (in order for them to
             * be patched using the same key map) so we need to account for that here
             * by disabling nested fragment wrappers from being generated.
             */
            true);
            context.pushStringPart(`</`);
            context.pushStringPart(tag.exp);
            context.pushStringPart(`>`);
        }
        else {
            // static tag
            context.pushStringPart(`<${tag.value.content}`);
            if (propsExp) {
                context.pushStringPart(propsExp);
            }
            context.pushStringPart(`>`);
            processChildren(node, context, false, true);
            context.pushStringPart(`</${tag.value.content}>`);
        }
    }
    else {
        // fragment
        processChildren(node, context, true, true);
    }
}

// We need to construct the slot functions in the 1st pass to ensure proper
// scope tracking, but the children of each slot cannot be processed until
// the 2nd pass, so we store the WIP slot functions in a weakMap during the 1st
// pass and complete them in the 2nd pass.
const wipMap$2 = new WeakMap();
const WIP_SLOT = Symbol();
const componentTypeMap = new WeakMap();
// ssr component transform is done in two phases:
// In phase 1. we use `buildSlot` to analyze the children of the component into
// WIP slot functions (it must be done in phase 1 because `buildSlot` relies on
// the core transform context).
// In phase 2. we convert the WIP slots from phase 1 into ssr-specific codegen
// nodes.
const ssrTransformComponent = (node, context) => {
    if (node.type !== 1 /* ELEMENT */ ||
        node.tagType !== 1 /* COMPONENT */) {
        return;
    }
    const component = compilerDom.resolveComponentType(node, context, true /* ssr */);
    const isDynamicComponent = shared.isObject(component) && component.callee === compilerDom.RESOLVE_DYNAMIC_COMPONENT;
    componentTypeMap.set(node, component);
    if (shared.isSymbol(component)) {
        if (component === compilerDom.SUSPENSE) {
            return ssrTransformSuspense(node, context);
        }
        if (component === compilerDom.TRANSITION_GROUP) {
            return ssrTransformTransitionGroup(node, context);
        }
        return; // other built-in components: fallthrough
    }
    // Build the fallback vnode-based branch for the component's slots.
    // We need to clone the node into a fresh copy and use the buildSlots' logic
    // to get access to the children of each slot. We then compile them with
    // a child transform pipeline using vnode-based transforms (instead of ssr-
    // based ones), and save the result branch (a ReturnStatement) in an array.
    // The branch is retrieved when processing slots again in ssr mode.
    const vnodeBranches = [];
    const clonedNode = clone(node);
    return function ssrPostTransformComponent() {
        // Using the cloned node, build the normal VNode-based branches (for
        // fallback in case the child is render-fn based). Store them in an array
        // for later use.
        if (clonedNode.children.length) {
            compilerDom.buildSlots(clonedNode, context, (props, children) => {
                vnodeBranches.push(createVNodeSlotBranch(props, children, context));
                return compilerDom.createFunctionExpression(undefined);
            });
        }
        let propsExp = `null`;
        if (node.props.length) {
            // note we are not passing ssr: true here because for components, v-on
            // handlers should still be passed
            const { props, directives } = compilerDom.buildProps(node, context, undefined, true, isDynamicComponent);
            if (props || directives.length) {
                propsExp = buildSSRProps(props, directives, context);
            }
        }
        const wipEntries = [];
        wipMap$2.set(node, wipEntries);
        const buildSSRSlotFn = (props, children, loc) => {
            const fn = compilerDom.createFunctionExpression([props || `_`, `_push`, `_parent`, `_scopeId`], undefined, // no return, assign body later
            true, // newline
            true, // isSlot
            loc);
            wipEntries.push({
                type: WIP_SLOT,
                fn,
                children,
                // also collect the corresponding vnode branch built earlier
                vnodeBranch: vnodeBranches[wipEntries.length]
            });
            return fn;
        };
        const slots = node.children.length
            ? compilerDom.buildSlots(node, context, buildSSRSlotFn).slots
            : `null`;
        if (typeof component !== 'string') {
            // dynamic component that resolved to a `resolveDynamicComponent` call
            // expression - since the resolved result may be a plain element (string)
            // or a VNode, handle it with `renderVNode`.
            node.ssrCodegenNode = compilerDom.createCallExpression(context.helper(SSR_RENDER_VNODE), [
                `_push`,
                compilerDom.createCallExpression(context.helper(compilerDom.CREATE_VNODE), [
                    component,
                    propsExp,
                    slots
                ]),
                `_parent`
            ]);
        }
        else {
            node.ssrCodegenNode = compilerDom.createCallExpression(context.helper(SSR_RENDER_COMPONENT), [component, propsExp, slots, `_parent`]);
        }
    };
};
function ssrProcessComponent(node, context, parent) {
    const component = componentTypeMap.get(node);
    if (!node.ssrCodegenNode) {
        // this is a built-in component that fell-through.
        if (component === compilerDom.TELEPORT) {
            return ssrProcessTeleport(node, context);
        }
        else if (component === compilerDom.SUSPENSE) {
            return ssrProcessSuspense(node, context);
        }
        else if (component === compilerDom.TRANSITION_GROUP) {
            return ssrProcessTransitionGroup(node, context);
        }
        else {
            // real fall-through: Transition / KeepAlive
            // just render its children.
            // #5352: if is at root level of a slot, push an empty string.
            // this does not affect the final output, but avoids all-comment slot
            // content of being treated as empty by ssrRenderSlot().
            if (parent.type === WIP_SLOT) {
                context.pushStringPart(``);
            }
            // #5351: filter out comment children inside transition
            if (component === compilerDom.TRANSITION) {
                node.children = node.children.filter(c => c.type !== 3 /* COMMENT */);
            }
            processChildren(node, context);
        }
    }
    else {
        // finish up slot function expressions from the 1st pass.
        const wipEntries = wipMap$2.get(node) || [];
        for (let i = 0; i < wipEntries.length; i++) {
            const { fn, vnodeBranch } = wipEntries[i];
            // For each slot, we generate two branches: one SSR-optimized branch and
            // one normal vnode-based branch. The branches are taken based on the
            // presence of the 2nd `_push` argument (which is only present if the slot
            // is called by `_ssrRenderSlot`.
            fn.body = compilerDom.createIfStatement(compilerDom.createSimpleExpression(`_push`, false), processChildrenAsStatement(wipEntries[i], context, false, true /* withSlotScopeId */), vnodeBranch);
        }
        // component is inside a slot, inherit slot scope Id
        if (context.withSlotScopeId) {
            node.ssrCodegenNode.arguments.push(`_scopeId`);
        }
        if (typeof component === 'string') {
            // static component
            context.pushStatement(compilerDom.createCallExpression(`_push`, [node.ssrCodegenNode]));
        }
        else {
            // dynamic component (`resolveDynamicComponent` call)
            // the codegen node is a `renderVNode` call
            context.pushStatement(node.ssrCodegenNode);
        }
    }
}
const rawOptionsMap = new WeakMap();
const [baseNodeTransforms, baseDirectiveTransforms] = compilerDom.getBaseTransformPreset(true);
const vnodeNodeTransforms = [...baseNodeTransforms, ...compilerDom.DOMNodeTransforms];
const vnodeDirectiveTransforms = {
    ...baseDirectiveTransforms,
    ...compilerDom.DOMDirectiveTransforms
};
function createVNodeSlotBranch(props, children, parentContext) {
    // apply a sub-transform using vnode-based transforms.
    const rawOptions = rawOptionsMap.get(parentContext.root);
    const subOptions = {
        ...rawOptions,
        // overwrite with vnode-based transforms
        nodeTransforms: [
            ...vnodeNodeTransforms,
            ...(rawOptions.nodeTransforms || [])
        ],
        directiveTransforms: {
            ...vnodeDirectiveTransforms,
            ...(rawOptions.directiveTransforms || {})
        }
    };
    // wrap the children with a wrapper template for proper children treatment.
    const wrapperNode = {
        type: 1 /* ELEMENT */,
        ns: 0 /* HTML */,
        tag: 'template',
        tagType: 3 /* TEMPLATE */,
        isSelfClosing: false,
        // important: provide v-slot="props" on the wrapper for proper
        // scope analysis
        props: [
            {
                type: 7 /* DIRECTIVE */,
                name: 'slot',
                exp: props,
                arg: undefined,
                modifiers: [],
                loc: compilerDom.locStub
            }
        ],
        children,
        loc: compilerDom.locStub,
        codegenNode: undefined
    };
    subTransform(wrapperNode, subOptions, parentContext);
    return compilerDom.createReturnStatement(children);
}
function subTransform(node, options, parentContext) {
    const childRoot = compilerDom.createRoot([node]);
    const childContext = compilerDom.createTransformContext(childRoot, options);
    // this sub transform is for vnode fallback branch so it should be handled
    // like normal render functions
    childContext.ssr = false;
    // inherit parent scope analysis state
    childContext.scopes = { ...parentContext.scopes };
    childContext.identifiers = { ...parentContext.identifiers };
    childContext.imports = parentContext.imports;
    // traverse
    compilerDom.traverseNode(childRoot, childContext);
    ['helpers', 'components', 'directives'].forEach(key => {
        childContext[key].forEach((value, helperKey) => {
            if (key === 'helpers') {
                const parentCount = parentContext.helpers.get(helperKey);
                if (parentCount === undefined) {
                    parentContext.helpers.set(helperKey, value);
                }
                else {
                    parentContext.helpers.set(helperKey, value + parentCount);
                }
            }
            else {
                parentContext[key].add(value);
            }
        });
    });
    // imports/hoists are not merged because:
    // - imports are only used for asset urls and should be consistent between
    //   node/client branches
    // - hoists are not enabled for the client branch here
}
function clone(v) {
    if (shared.isArray(v)) {
        return v.map(clone);
    }
    else if (shared.isObject(v)) {
        const res = {};
        for (const key in v) {
            res[key] = clone(v[key]);
        }
        return res;
    }
    else {
        return v;
    }
}

// Because SSR codegen output is completely different from client-side output
// (e.g. multiple elements can be concatenated into a single template literal
// instead of each getting a corresponding call), we need to apply an extra
// transform pass to convert the template AST into a fresh JS AST before
// passing it to codegen.
function ssrCodegenTransform(ast, options) {
    const context = createSSRTransformContext(ast, options);
    // inject SFC <style> CSS variables
    // we do this instead of inlining the expression to ensure the vars are
    // only resolved once per render
    if (options.ssrCssVars) {
        const varsExp = compilerDom.processExpression(compilerDom.createSimpleExpression(options.ssrCssVars, false), compilerDom.createTransformContext(compilerDom.createRoot([]), options));
        context.body.push(compilerDom.createCompoundExpression([`const _cssVars = { style: `, varsExp, `}`]));
    }
    const isFragment = ast.children.length > 1 && ast.children.some(c => !compilerDom.isText(c));
    processChildren(ast, context, isFragment);
    ast.codegenNode = compilerDom.createBlockStatement(context.body);
    // Finalize helpers.
    // We need to separate helpers imported from 'vue' vs. '@vue/server-renderer'
    ast.ssrHelpers = Array.from(new Set([...ast.helpers.filter(h => h in ssrHelpers), ...context.helpers]));
    ast.helpers = ast.helpers.filter(h => !(h in ssrHelpers));
}
function createSSRTransformContext(root, options, helpers = new Set(), withSlotScopeId = false) {
    const body = [];
    let currentString = null;
    return {
        root,
        options,
        body,
        helpers,
        withSlotScopeId,
        onError: options.onError ||
            (e => {
                throw e;
            }),
        helper(name) {
            helpers.add(name);
            return name;
        },
        pushStringPart(part) {
            if (!currentString) {
                const currentCall = compilerDom.createCallExpression(`_push`);
                body.push(currentCall);
                currentString = compilerDom.createTemplateLiteral([]);
                currentCall.arguments.push(currentString);
            }
            const bufferedElements = currentString.elements;
            const lastItem = bufferedElements[bufferedElements.length - 1];
            if (shared.isString(part) && shared.isString(lastItem)) {
                bufferedElements[bufferedElements.length - 1] += part;
            }
            else {
                bufferedElements.push(part);
            }
        },
        pushStatement(statement) {
            // close current string
            currentString = null;
            body.push(statement);
        }
    };
}
function createChildContext(parent, withSlotScopeId = parent.withSlotScopeId) {
    // ensure child inherits parent helpers
    return createSSRTransformContext(parent.root, parent.options, parent.helpers, withSlotScopeId);
}
function processChildren(parent, context, asFragment = false, disableNestedFragments = false) {
    if (asFragment) {
        context.pushStringPart(`<!--[-->`);
    }
    const { children } = parent;
    for (let i = 0; i < children.length; i++) {
        const child = children[i];
        switch (child.type) {
            case 1 /* ELEMENT */:
                switch (child.tagType) {
                    case 0 /* ELEMENT */:
                        ssrProcessElement(child, context);
                        break;
                    case 1 /* COMPONENT */:
                        ssrProcessComponent(child, context, parent);
                        break;
                    case 2 /* SLOT */:
                        ssrProcessSlotOutlet(child, context);
                        break;
                    case 3 /* TEMPLATE */:
                        // TODO
                        break;
                    default:
                        context.onError(createSSRCompilerError(63 /* X_SSR_INVALID_AST_NODE */, child.loc));
                        // make sure we exhaust all possible types
                        const exhaustiveCheck = child;
                        return exhaustiveCheck;
                }
                break;
            case 2 /* TEXT */:
                context.pushStringPart(shared.escapeHtml(child.content));
                break;
            case 3 /* COMMENT */:
                // no need to escape comment here because the AST can only
                // contain valid comments.
                context.pushStringPart(`<!--${child.content}-->`);
                break;
            case 5 /* INTERPOLATION */:
                context.pushStringPart(compilerDom.createCallExpression(context.helper(SSR_INTERPOLATE), [child.content]));
                break;
            case 9 /* IF */:
                ssrProcessIf(child, context, disableNestedFragments);
                break;
            case 11 /* FOR */:
                ssrProcessFor(child, context, disableNestedFragments);
                break;
            case 10 /* IF_BRANCH */:
                // no-op - handled by ssrProcessIf
                break;
            case 12 /* TEXT_CALL */:
            case 8 /* COMPOUND_EXPRESSION */:
                // no-op - these two types can never appear as template child node since
                // `transformText` is not used during SSR compile.
                break;
            default:
                context.onError(createSSRCompilerError(63 /* X_SSR_INVALID_AST_NODE */, child.loc));
                // make sure we exhaust all possible types
                const exhaustiveCheck = child;
                return exhaustiveCheck;
        }
    }
    if (asFragment) {
        context.pushStringPart(`<!--]-->`);
    }
}
function processChildrenAsStatement(parent, parentContext, asFragment = false, withSlotScopeId = parentContext.withSlotScopeId) {
    const childContext = createChildContext(parentContext, withSlotScopeId);
    processChildren(parent, childContext, asFragment);
    return compilerDom.createBlockStatement(childContext.body);
}

const ssrTransformModel = (dir, node, context) => {
    const model = dir.exp;
    function checkDuplicatedValue() {
        const value = compilerDom.findProp(node, 'value');
        if (value) {
            context.onError(compilerDom.createDOMCompilerError(57 /* X_V_MODEL_UNNECESSARY_VALUE */, value.loc));
        }
    }
    if (node.tagType === 0 /* ELEMENT */) {
        const res = { props: [] };
        const defaultProps = [
            // default value binding for text type inputs
            compilerDom.createObjectProperty(`value`, model)
        ];
        if (node.tag === 'input') {
            const type = compilerDom.findProp(node, 'type');
            if (type) {
                const value = findValueBinding(node);
                if (type.type === 7 /* DIRECTIVE */) {
                    // dynamic type
                    res.ssrTagParts = [
                        compilerDom.createCallExpression(context.helper(SSR_RENDER_DYNAMIC_MODEL), [
                            type.exp,
                            model,
                            value
                        ])
                    ];
                }
                else if (type.value) {
                    // static type
                    switch (type.value.content) {
                        case 'radio':
                            res.props = [
                                compilerDom.createObjectProperty(`checked`, compilerDom.createCallExpression(context.helper(SSR_LOOSE_EQUAL), [
                                    model,
                                    value
                                ]))
                            ];
                            break;
                        case 'checkbox':
                            const trueValueBinding = compilerDom.findProp(node, 'true-value');
                            if (trueValueBinding) {
                                const trueValue = trueValueBinding.type === 6 /* ATTRIBUTE */
                                    ? JSON.stringify(trueValueBinding.value.content)
                                    : trueValueBinding.exp;
                                res.props = [
                                    compilerDom.createObjectProperty(`checked`, compilerDom.createCallExpression(context.helper(SSR_LOOSE_EQUAL), [
                                        model,
                                        trueValue
                                    ]))
                                ];
                            }
                            else {
                                res.props = [
                                    compilerDom.createObjectProperty(`checked`, compilerDom.createConditionalExpression(compilerDom.createCallExpression(`Array.isArray`, [model]), compilerDom.createCallExpression(context.helper(SSR_LOOSE_CONTAIN), [
                                        model,
                                        value
                                    ]), model))
                                ];
                            }
                            break;
                        case 'file':
                            context.onError(compilerDom.createDOMCompilerError(56 /* X_V_MODEL_ON_FILE_INPUT_ELEMENT */, dir.loc));
                            break;
                        default:
                            checkDuplicatedValue();
                            res.props = defaultProps;
                            break;
                    }
                }
            }
            else if (compilerDom.hasDynamicKeyVBind(node)) ;
            else {
                // text type
                checkDuplicatedValue();
                res.props = defaultProps;
            }
        }
        else if (node.tag === 'textarea') {
            checkDuplicatedValue();
            node.children = [compilerDom.createInterpolation(model, model.loc)];
        }
        else if (node.tag === 'select') ;
        else {
            context.onError(compilerDom.createDOMCompilerError(54 /* X_V_MODEL_ON_INVALID_ELEMENT */, dir.loc));
        }
        return res;
    }
    else {
        // component v-model
        return compilerDom.transformModel(dir, node, context);
    }
};
function findValueBinding(node) {
    const valueBinding = compilerDom.findProp(node, 'value');
    return valueBinding
        ? valueBinding.type === 7 /* DIRECTIVE */
            ? valueBinding.exp
            : compilerDom.createSimpleExpression(valueBinding.value.content, true)
        : compilerDom.createSimpleExpression(`null`, false);
}

const ssrTransformShow = (dir, node, context) => {
    if (!dir.exp) {
        context.onError(compilerDom.createDOMCompilerError(58 /* X_V_SHOW_NO_EXPRESSION */));
    }
    return {
        props: [
            compilerDom.createObjectProperty(`style`, compilerDom.createConditionalExpression(dir.exp, compilerDom.createSimpleExpression(`null`, false), compilerDom.createObjectExpression([
                compilerDom.createObjectProperty(`display`, compilerDom.createSimpleExpression(`none`, true))
            ]), false /* no newline */))
        ]
    };
};

const filterChild = (node) => node.children.filter(n => n.type !== 3 /* COMMENT */);
const hasSingleChild = (node) => filterChild(node).length === 1;
const ssrInjectFallthroughAttrs = (node, context) => {
    // _attrs is provided as a function argument.
    // mark it as a known identifier so that it doesn't get prefixed by
    // transformExpression.
    if (node.type === 0 /* ROOT */) {
        context.identifiers._attrs = 1;
    }
    if (node.type === 1 /* ELEMENT */ &&
        node.tagType === 1 /* COMPONENT */ &&
        (compilerDom.isBuiltInType(node.tag, 'Transition') ||
            compilerDom.isBuiltInType(node.tag, 'KeepAlive'))) {
        const rootChildren = filterChild(context.root);
        if (rootChildren.length === 1 && rootChildren[0] === node) {
            if (hasSingleChild(node)) {
                injectFallthroughAttrs(node.children[0]);
            }
            return;
        }
    }
    const parent = context.parent;
    if (!parent || parent.type !== 0 /* ROOT */) {
        return;
    }
    if (node.type === 10 /* IF_BRANCH */ && hasSingleChild(node)) {
        // detect cases where the parent v-if is not the only root level node
        let hasEncounteredIf = false;
        for (const c of filterChild(parent)) {
            if (c.type === 9 /* IF */ ||
                (c.type === 1 /* ELEMENT */ && compilerDom.findDir(c, 'if'))) {
                // multiple root v-if
                if (hasEncounteredIf)
                    return;
                hasEncounteredIf = true;
            }
            else if (
            // node before v-if
            !hasEncounteredIf ||
                // non else nodes
                !(c.type === 1 /* ELEMENT */ && compilerDom.findDir(c, /else/, true))) {
                return;
            }
        }
        injectFallthroughAttrs(node.children[0]);
    }
    else if (hasSingleChild(parent)) {
        injectFallthroughAttrs(node);
    }
};
function injectFallthroughAttrs(node) {
    if (node.type === 1 /* ELEMENT */ &&
        (node.tagType === 0 /* ELEMENT */ ||
            node.tagType === 1 /* COMPONENT */) &&
        !compilerDom.findDir(node, 'for')) {
        node.props.push({
            type: 7 /* DIRECTIVE */,
            name: 'bind',
            arg: undefined,
            exp: compilerDom.createSimpleExpression(`_attrs`, false),
            modifiers: [],
            loc: compilerDom.locStub
        });
    }
}

const ssrInjectCssVars = (node, context) => {
    if (!context.ssrCssVars) {
        return;
    }
    // _cssVars is initialized once per render function
    // the code is injected in ssrCodegenTransform when creating the
    // ssr transform context
    if (node.type === 0 /* ROOT */) {
        context.identifiers._cssVars = 1;
    }
    const parent = context.parent;
    if (!parent || parent.type !== 0 /* ROOT */) {
        return;
    }
    if (node.type === 10 /* IF_BRANCH */) {
        for (const child of node.children) {
            injectCssVars(child);
        }
    }
    else {
        injectCssVars(node);
    }
};
function injectCssVars(node) {
    if (node.type === 1 /* ELEMENT */ &&
        (node.tagType === 0 /* ELEMENT */ ||
            node.tagType === 1 /* COMPONENT */) &&
        !compilerDom.findDir(node, 'for')) {
        if (compilerDom.isBuiltInType(node.tag, 'Suspense')) {
            for (const child of node.children) {
                if (child.type === 1 /* ELEMENT */ &&
                    child.tagType === 3 /* TEMPLATE */) {
                    // suspense slot
                    child.children.forEach(injectCssVars);
                }
                else {
                    injectCssVars(child);
                }
            }
        }
        else {
            node.props.push({
                type: 7 /* DIRECTIVE */,
                name: 'bind',
                arg: undefined,
                exp: compilerDom.createSimpleExpression(`_cssVars`, false),
                modifiers: [],
                loc: compilerDom.locStub
            });
        }
    }
}

function compile(template, options = {}) {
    options = {
        ...options,
        // apply DOM-specific parsing options
        ...compilerDom.parserOptions,
        ssr: true,
        inSSR: true,
        scopeId: options.mode === 'function' ? null : options.scopeId,
        // always prefix since compiler-ssr doesn't have size concern
        prefixIdentifiers: true,
        // disable optimizations that are unnecessary for ssr
        cacheHandlers: false,
        hoistStatic: false
    };
    const ast = compilerDom.baseParse(template, options);
    // Save raw options for AST. This is needed when performing sub-transforms
    // on slot vnode branches.
    rawOptionsMap.set(ast, options);
    compilerDom.transform(ast, {
        ...options,
        hoistStatic: false,
        nodeTransforms: [
            ssrTransformIf,
            ssrTransformFor,
            compilerDom.trackVForSlotScopes,
            compilerDom.transformExpression,
            ssrTransformSlotOutlet,
            ssrInjectFallthroughAttrs,
            ssrInjectCssVars,
            ssrTransformElement,
            ssrTransformComponent,
            compilerDom.trackSlotScopes,
            compilerDom.transformStyle,
            ...(options.nodeTransforms || []) // user transforms
        ],
        directiveTransforms: {
            // reusing core v-bind
            bind: compilerDom.transformBind,
            on: compilerDom.transformOn,
            // model and show has dedicated SSR handling
            model: ssrTransformModel,
            show: ssrTransformShow,
            // the following are ignored during SSR
            // on: noopDirectiveTransform,
            cloak: compilerDom.noopDirectiveTransform,
            once: compilerDom.noopDirectiveTransform,
            memo: compilerDom.noopDirectiveTransform,
            ...(options.directiveTransforms || {}) // user transforms
        }
    });
    // traverse the template AST and convert into SSR codegen AST
    // by replacing ast.codegenNode.
    ssrCodegenTransform(ast, options);
    return compilerDom.generate(ast, options);
}

exports.compile = compile;
