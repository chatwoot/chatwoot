import * as React from 'react';
/**
 * @desc Utility type for getting props type of React component.
 * It takes `defaultProps` into an account - making props with defaults optional.
 */
export type PropsOf<C extends keyof JSX.IntrinsicElements | React.JSXElementConstructor<any>> = JSX.LibraryManagedAttributes<C, React.ComponentProps<C>>;
// We need to use this version of Omit as it's distributive (Will preserve unions)
export type DistributiveOmit<T, U> = T extends any ? Pick<T, Exclude<keyof T, U>> : never;
