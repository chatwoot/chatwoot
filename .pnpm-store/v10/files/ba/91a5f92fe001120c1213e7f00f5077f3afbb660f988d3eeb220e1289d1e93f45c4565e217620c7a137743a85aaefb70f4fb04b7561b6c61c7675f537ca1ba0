import { Buffer } from 'buffer';
import { noChange, _$LH } from './lit-html.js';
import { PartType } from './directive.js';
import { isPrimitive, isTemplateResult, isCompiledTemplateResult, isSingleExpression } from './directive-helpers.js';

const { _TemplateInstance: TemplateInstance, _isIterable: isIterable, _resolveDirective: resolveDirective, _ChildPart: ChildPart, _ElementPart: ElementPart, } = _$LH;
/**
 * hydrate() operates on a container with server-side rendered content and
 * restores the client side data structures needed for lit-html updates such as
 * TemplateInstances and Parts. After calling `hydrate`, lit-html will behave as
 * if it initially rendered the DOM, and any subsequent updates will update
 * efficiently, the same as if lit-html had rendered the DOM on the client.
 *
 * hydrate() must be called on DOM that adheres the to lit-ssr structure for
 * parts. ChildParts must be represented with both a start and end comment
 * marker, and ChildParts that contain a TemplateInstance must have the template
 * digest written into the comment data.
 *
 * Since render() encloses its output in a ChildPart, there must always be a root
 * ChildPart.
 *
 * Example (using for # ... for annotations in HTML)
 *
 * Given this input:
 *
 *   html`<div class=${x}>${y}</div>`
 *
 * The SSR DOM is:
 *
 *   <!--lit-part AEmR7W+R0Ak=-->  # Start marker for the root ChildPart created
 *                                 # by render(). Includes the digest of the
 *                                 # template
 *   <div class="TEST_X">
 *     <!--lit-node 0--> # Indicates there are attribute bindings here
 *                           # The number is the depth-first index of the parent
 *                           # node in the template.
 *     <!--lit-part-->  # Start marker for the ${x} expression
 *     TEST_Y
 *     <!--/lit-part-->  # End marker for the ${x} expression
 *   </div>
 *
 *   <!--/lit-part-->  # End marker for the root ChildPart
 *
 * @param rootValue
 * @param container
 * @param userOptions
 *
 * @deprecated This has been moved to `@lit-labs/ssr-client` and will be removed
 * in a future release.
 */
const hydrate = (rootValue, container, options = {}) => {
    console.warn('Importing `hydrate()` from `lit-html/experimental-hydrate.js` is deprecated.' +
        'Import from `@lit-labs/ssr-client` instead.');
    // TODO(kschaaf): Do we need a helper for _$litPart$ ("part for node")?
    // This property needs to remain unminified.
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    if (container['_$litPart$'] !== undefined) {
        throw new Error('container already contains a live render');
    }
    // Since render() creates a ChildPart to render into, we'll always have
    // exactly one root part. We need to hold a reference to it so we can set
    // it in the parts cache.
    let rootPart = undefined;
    // Used for error messages
    let rootPartMarker = undefined;
    // When we are in-between ChildPart markers, this is the current ChildPart.
    // It's needed to be able to set the ChildPart's endNode when we see a
    // close marker
    let currentChildPart = undefined;
    // Used to remember parent template state as we recurse into nested
    // templates
    const stack = [];
    const walker = document.createTreeWalker(container, NodeFilter.SHOW_COMMENT, null, false);
    let marker;
    // Walk the DOM looking for part marker comments
    while ((marker = walker.nextNode()) !== null) {
        const markerText = marker.data;
        if (markerText.startsWith('lit-part')) {
            if (stack.length === 0 && rootPart !== undefined) {
                throw new Error(`There must be only one root part per container. ` +
                    `Found a part marker (${marker}) when we already have a root ` +
                    `part marker (${rootPartMarker})`);
            }
            // Create a new ChildPart and push it onto the stack
            currentChildPart = openChildPart(rootValue, marker, stack, options);
            rootPart !== null && rootPart !== void 0 ? rootPart : (rootPart = currentChildPart);
            rootPartMarker !== null && rootPartMarker !== void 0 ? rootPartMarker : (rootPartMarker = marker);
        }
        else if (markerText.startsWith('lit-node')) {
            // Create and hydrate attribute parts into the current ChildPart on the
            // stack
            createAttributeParts(marker, stack, options);
        }
        else if (markerText.startsWith('/lit-part')) {
            // Close the current ChildPart, and pop the previous one off the stack
            if (stack.length === 1 && currentChildPart !== rootPart) {
                throw new Error('internal error');
            }
            currentChildPart = closeChildPart(marker, currentChildPart, stack);
        }
    }
    if (rootPart === undefined) {
        const elementMessage = container instanceof ShadowRoot
            ? `{container.host.localName}'s shadow root`
            : container instanceof DocumentFragment
                ? 'DocumentFragment'
                : container.localName;
        console.error(`There should be exactly one root part in a render container, ` +
            `but we didn't find any in ${elementMessage}.`);
    } // This property needs to remain unminified.
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    container['_$litPart$'] = rootPart;
};
const openChildPart = (rootValue, marker, stack, options) => {
    let value;
    // We know the startNode now. We'll know the endNode when we get to
    // the matching marker and set it in closeChildPart()
    // TODO(kschaaf): Current constructor takes both nodes
    let part;
    if (stack.length === 0) {
        part = new ChildPart(marker, null, undefined, options);
        value = rootValue;
    }
    else {
        const state = stack[stack.length - 1];
        if (state.type === 'template-instance') {
            part = new ChildPart(marker, null, state.instance, options);
            state.instance._$parts.push(part);
            value = state.result.values[state.instancePartIndex++];
            state.templatePartIndex++;
        }
        else if (state.type === 'iterable') {
            part = new ChildPart(marker, null, state.part, options);
            const result = state.iterator.next();
            if (result.done) {
                value = undefined;
                state.done = true;
                throw new Error('Unhandled shorter than expected iterable');
            }
            else {
                value = result.value;
            }
            state.part._$committedValue.push(part);
        }
        else {
            // state.type === 'leaf'
            // TODO(kschaaf): This is unexpected, and likely a result of a primitive
            // been rendered on the client when a TemplateResult was rendered on the
            // server; this part will be hydrated but not used. We can detect it, but
            // we need to decide what to do in this case. Note that this part won't be
            // retained by any parent TemplateInstance, since a primitive had been
            // rendered in its place.
            // https://github.com/lit/lit/issues/1434
            // throw new Error('Hydration value mismatch: Found a TemplateInstance' +
            //  'where a leaf value was expected');
            part = new ChildPart(marker, null, state.part, options);
        }
    }
    // Initialize the ChildPart state depending on the type of value and push
    // it onto the stack. This logic closely follows the ChildPart commit()
    // cascade order:
    // 1. directive
    // 2. noChange
    // 3. primitive (note strings must be handled before iterables, since they
    //    are iterable)
    // 4. TemplateResult
    // 5. Node (not yet implemented, but fallback handling is fine)
    // 6. Iterable
    // 7. nothing (handled in fallback)
    // 8. Fallback for everything else
    value = resolveDirective(part, value);
    if (value === noChange) {
        stack.push({ part, type: 'leaf' });
    }
    else if (isPrimitive(value)) {
        stack.push({ part, type: 'leaf' });
        part._$committedValue = value;
        // TODO(kschaaf): We can detect when a primitive is being hydrated on the
        // client where a TemplateResult was rendered on the server, but we need to
        // decide on a strategy for what to do next.
        // https://github.com/lit/lit/issues/1434
        // if (marker.data !== 'lit-part') {
        //   throw new Error('Hydration value mismatch: Primitive found where TemplateResult expected');
        // }
    }
    else if (isTemplateResult(value)) {
        if (isCompiledTemplateResult(value)) {
            throw new Error('compiled templates are not supported');
        }
        // Check for a template result digest
        const markerWithDigest = `lit-part ${digestForTemplateResult(value)}`;
        if (marker.data === markerWithDigest) {
            const template = ChildPart.prototype._$getTemplate(value);
            const instance = new TemplateInstance(template, part);
            stack.push({
                type: 'template-instance',
                instance,
                part,
                templatePartIndex: 0,
                instancePartIndex: 0,
                result: value,
            });
            // For TemplateResult values, we set the part value to the
            // generated TemplateInstance
            part._$committedValue = instance;
        }
        else {
            // TODO: if this isn't the server-rendered template, do we
            // need to stop hydrating this subtree? Clear it? Add tests.
            throw new Error('Hydration value mismatch: Unexpected TemplateResult rendered to part');
        }
    }
    else if (isIterable(value)) {
        // currentChildPart.value will contain an array of ChildParts
        stack.push({
            part: part,
            type: 'iterable',
            value,
            iterator: value[Symbol.iterator](),
            done: false,
        });
        part._$committedValue = [];
    }
    else {
        // Fallback for everything else (nothing, Objects, Functions,
        // etc.): we just initialize the part's value
        // Note that `Node` value types are not currently supported during
        // SSR, so that part of the cascade is missing.
        stack.push({ part: part, type: 'leaf' });
        part._$committedValue = value == null ? '' : value;
    }
    return part;
};
const closeChildPart = (marker, part, stack) => {
    if (part === undefined) {
        throw new Error('unbalanced part marker');
    }
    part._$endNode = marker;
    const currentState = stack.pop();
    if (currentState.type === 'iterable') {
        if (!currentState.iterator.next().done) {
            throw new Error('unexpected longer than expected iterable');
        }
    }
    if (stack.length > 0) {
        const state = stack[stack.length - 1];
        return state.part;
    }
    else {
        return undefined;
    }
};
const createAttributeParts = (comment, stack, options) => {
    // Get the nodeIndex from DOM. We're only using this for an integrity
    // check right now, we might not need it.
    const match = /lit-node (\d+)/.exec(comment.data);
    const nodeIndex = parseInt(match[1]);
    // Node markers are added as a previous sibling to identify elements
    // with attribute/property/element/event bindings or custom elements
    // whose `defer-hydration` attribute needs to be removed
    const node = comment.nextElementSibling;
    if (node === null) {
        throw new Error('could not find node for attribute parts');
    }
    // Remove `defer-hydration` attribute, if any
    node.removeAttribute('defer-hydration');
    const state = stack[stack.length - 1];
    if (state.type === 'template-instance') {
        const instance = state.instance;
        // eslint-disable-next-line no-constant-condition
        while (true) {
            // If the next template part is in attribute-position on the current node,
            // create the instance part for it and prime its state
            const templatePart = instance._$template.parts[state.templatePartIndex];
            if (templatePart === undefined ||
                (templatePart.type !== PartType.ATTRIBUTE &&
                    templatePart.type !== PartType.ELEMENT) ||
                templatePart.index !== nodeIndex) {
                break;
            }
            if (templatePart.type === PartType.ATTRIBUTE) {
                // The instance part is created based on the constructor saved in the
                // template part
                const instancePart = new templatePart.ctor(node, templatePart.name, templatePart.strings, state.instance, options);
                const value = isSingleExpression(instancePart)
                    ? state.result.values[state.instancePartIndex]
                    : state.result.values;
                // Setting the attribute value primes committed value with the resolved
                // directive value; we only then commit that value for event/property
                // parts since those were not serialized, and pass `noCommit` for the
                // others to avoid perf impact of touching the DOM unnecessarily
                const noCommit = !(instancePart.type === PartType.EVENT ||
                    instancePart.type === PartType.PROPERTY);
                instancePart._$setValue(value, instancePart, state.instancePartIndex, noCommit);
                state.instancePartIndex += templatePart.strings.length - 1;
                instance._$parts.push(instancePart);
            }
            else {
                // templatePart.type === PartType.ELEMENT
                const instancePart = new ElementPart(node, state.instance, options);
                resolveDirective(instancePart, state.result.values[state.instancePartIndex++]);
                instance._$parts.push(instancePart);
            }
            state.templatePartIndex++;
        }
    }
    else {
        throw new Error('internal error');
    }
};
// Number of 32 bit elements to use to create template digests
const digestSize = 2;
// We need to specify a digest to use across rendering environments. This is a
// simple digest build from a DJB2-ish hash modified from:
// https://github.com/darkskyapp/string-hash/blob/master/index.js
// It has been changed to an array of hashes to add additional bits.
// Goals:
//  - Extremely low collision rate. We may not be able to detect collisions.
//  - Extremely fast.
//  - Extremely small code size.
//  - Safe to include in HTML comment text or attribute value.
//  - Easily specifiable and implementable in multiple languages.
// We don't care about cryptographic suitability.
const digestForTemplateResult = (templateResult) => {
    const hashes = new Uint32Array(digestSize).fill(5381);
    for (const s of templateResult.strings) {
        for (let i = 0; i < s.length; i++) {
            hashes[i % digestSize] = (hashes[i % digestSize] * 33) ^ s.charCodeAt(i);
        }
    }
    const str = String.fromCharCode(...new Uint8Array(hashes.buffer));
    // Use `btoa` in browsers because it is supported universally.
    //
    // In Node, we are sometimes executing in an isolated VM context, which means
    // neither `btoa` nor `Buffer` will be globally available by default (also
    // note that `btoa` is only supported in Node 16+ anyway, and we still support
    // Node 14). Instead of requiring users to always provide an implementation
    // for `btoa` when they set up their VM context, we instead inject an import
    // for `Buffer` from Node's built-in `buffer` module in our Rollup config (see
    // note at the top of this file), and use that.
    return Buffer.from(str, 'binary').toString('base64') ;
};

export { digestForTemplateResult, hydrate };
//# sourceMappingURL=experimental-hydrate.js.map
