/**
 * @license
 * Copyright 2017 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */
import { ReactiveElement } from '../reactive-element.js';
/**
 * Generates a public interface type that removes private and protected fields.
 * This allows accepting otherwise compatible versions of the type (e.g. from
 * multiple copies of the same package in `node_modules`).
 */
export declare type Interface<T> = {
    [K in keyof T]: T[K];
};
export declare type Constructor<T> = {
    new (...args: any[]): T;
};
export interface ClassDescriptor {
    kind: 'class';
    elements: ClassElement[];
    finisher?: <T>(clazz: Constructor<T>) => void | Constructor<T>;
}
export interface ClassElement {
    kind: 'field' | 'method';
    key: PropertyKey;
    placement: 'static' | 'prototype' | 'own';
    initializer?: Function;
    extras?: ClassElement[];
    finisher?: <T>(clazz: Constructor<T>) => void | Constructor<T>;
    descriptor?: PropertyDescriptor;
}
export declare const legacyPrototypeMethod: (descriptor: PropertyDescriptor, proto: Object, name: PropertyKey) => void;
export declare const standardPrototypeMethod: (descriptor: PropertyDescriptor, element: ClassElement) => {
    kind: string;
    placement: string;
    key: PropertyKey;
    descriptor: PropertyDescriptor;
};
/**
 * Helper for decorating a property that is compatible with both TypeScript
 * and Babel decorators. The optional `finisher` can be used to perform work on
 * the class. The optional `descriptor` should return a PropertyDescriptor
 * to install for the given property.
 *
 * @param finisher {function} Optional finisher method; receives the element
 * constructor and property key as arguments and has no return value.
 * @param descriptor {function} Optional descriptor method; receives the
 * property key as an argument and returns a property descriptor to define for
 * the given property.
 * @returns {ClassElement|void}
 */
export declare const decorateProperty: ({ finisher, descriptor, }: {
    finisher?: ((ctor: typeof ReactiveElement, property: PropertyKey) => void) | null | undefined;
    descriptor?: ((property: PropertyKey) => PropertyDescriptor) | undefined;
}) => (protoOrDescriptor: Interface<ReactiveElement> | ClassElement, name?: PropertyKey) => void | any;
//# sourceMappingURL=base.d.ts.map