import * as React from 'react';
import React__default, { FunctionComponent } from 'react';
import posthogJs, { PostHogConfig, JsonType } from 'posthog-js';

type PostHog = typeof posthogJs;
declare const PostHogContext: React.Context<{
    client: PostHog;
}>;

type WithOptionalChildren<T> = T & {
    children?: React__default.ReactNode | undefined;
};
type PostHogProviderProps = {
    client: PostHog;
    apiKey?: never;
    options?: never;
} | {
    apiKey: string;
    options?: Partial<PostHogConfig>;
    client?: never;
};
declare function PostHogProvider({ children, client, apiKey, options }: WithOptionalChildren<PostHogProviderProps>): React__default.JSX.Element;

declare function useFeatureFlagEnabled(flag: string): boolean | undefined;

declare function useFeatureFlagPayload(flag: string): JsonType;

declare function useActiveFeatureFlags(): string[];

declare function useFeatureFlagVariantKey(flag: string): string | boolean | undefined;

declare const usePostHog: () => PostHog;

type PostHogFeatureProps = React__default.HTMLProps<HTMLDivElement> & {
    flag: string;
    children: React__default.ReactNode | ((payload: any) => React__default.ReactNode);
    fallback?: React__default.ReactNode;
    match?: string | boolean;
    visibilityObserverOptions?: IntersectionObserverInit;
    trackInteraction?: boolean;
    trackView?: boolean;
};
declare function PostHogFeature({ flag, match, children, fallback, visibilityObserverOptions, trackInteraction, trackView, ...props }: PostHogFeatureProps): JSX.Element | null;

type Properties = Record<string, any>;
type PostHogErrorBoundaryFallbackProps = {
    error: unknown;
    exceptionEvent: unknown;
    componentStack: string;
};
type PostHogErrorBoundaryProps = {
    children?: React__default.ReactNode | (() => React__default.ReactNode);
    fallback?: React__default.ReactNode | FunctionComponent<PostHogErrorBoundaryFallbackProps>;
    additionalProperties?: Properties | ((error: unknown) => Properties);
};
type PostHogErrorBoundaryState = {
    componentStack: string | null;
    exceptionEvent: unknown;
    error: unknown;
};
declare class PostHogErrorBoundary extends React__default.Component<PostHogErrorBoundaryProps, PostHogErrorBoundaryState> {
    static contextType: React__default.Context<{
        client: PostHog;
    }>;
    constructor(props: PostHogErrorBoundaryProps);
    componentDidCatch(error: unknown, errorInfo: React__default.ErrorInfo): void;
    render(): React__default.ReactNode;
}

export { type PostHog, PostHogContext, PostHogErrorBoundary, type PostHogErrorBoundaryFallbackProps, type PostHogErrorBoundaryProps, PostHogFeature, type PostHogFeatureProps, PostHogProvider, useActiveFeatureFlags, useFeatureFlagEnabled, useFeatureFlagPayload, useFeatureFlagVariantKey, usePostHog };
