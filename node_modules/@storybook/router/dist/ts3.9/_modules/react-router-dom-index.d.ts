import * as React from "react";
import { MemoryRouter, Navigate, Outlet, Route, Router, Routes, createRoutesFromChildren, generatePath, matchRoutes, matchPath, resolvePath, renderMatches, useHref, useInRouterContext, useLocation, useMatch, useNavigate, useNavigationType, useOutlet, useParams, useResolvedPath, useRoutes } from "./react-router-index";
import type { To } from "./react-router-index";
export { MemoryRouter, Navigate, Outlet, Route, Router, Routes, createRoutesFromChildren, generatePath, matchRoutes, matchPath, renderMatches, resolvePath, useHref, useInRouterContext, useLocation, useMatch, useNavigate, useNavigationType, useOutlet, useParams, useResolvedPath, useRoutes };
export type { Location, Path, To, NavigationType, MemoryRouterProps, NavigateFunction, NavigateOptions, NavigateProps, Navigator, OutletProps, Params, PathMatch, RouteMatch, RouteObject, RouteProps, PathRouteProps, LayoutRouteProps, IndexRouteProps, RouterProps, RoutesProps } from "./react-router-index";
/** @internal */
export { UNSAFE_NavigationContext, UNSAFE_LocationContext, UNSAFE_RouteContext } from "./react-router-index";
export interface BrowserRouterProps {
    basename?: string;
    children?: React.ReactNode;
    window?: Window;
}
/**
 * A <Router> for use in web browsers. Provides the cleanest URLs.
 */
export declare function BrowserRouter({ basename, children, window }: BrowserRouterProps): JSX.Element;
export interface HashRouterProps {
    basename?: string;
    children?: React.ReactNode;
    window?: Window;
}
/**
 * A <Router> for use in web browsers. Stores the location in the hash
 * portion of the URL so it is not sent to the server.
 */
export declare function HashRouter({ basename, children, window }: HashRouterProps): JSX.Element;
export interface LinkProps extends Omit<React.AnchorHTMLAttributes<HTMLAnchorElement>, "href"> {
    reloadDocument?: boolean;
    replace?: boolean;
    state?: any;
    to: To;
}
/**
 * The public API for rendering a history-aware <a>.
 */
export declare const Link: React.ForwardRefExoticComponent<LinkProps & React.RefAttributes<HTMLAnchorElement>>;
export interface NavLinkProps extends Omit<LinkProps, "className" | "style"> {
    caseSensitive?: boolean;
    className?: string | ((props: {
        isActive: boolean;
    }) => string);
    end?: boolean;
    style?: React.CSSProperties | ((props: {
        isActive: boolean;
    }) => React.CSSProperties);
}
/**
 * A <Link> wrapper that knows if it's "active" or not.
 */
export declare const NavLink: React.ForwardRefExoticComponent<NavLinkProps & React.RefAttributes<HTMLAnchorElement>>;
/**
 * Handles the click behavior for router `<Link>` components. This is useful if
 * you need to create custom `<Link>` components with the same click behavior we
 * use in our exported `<Link>`.
 */
export declare function useLinkClickHandler<E extends Element = HTMLAnchorElement>(to: To, { target, replace: replaceProp, state }?: {
    target?: React.HTMLAttributeAnchorTarget;
    replace?: boolean;
    state?: any;
}): (event: React.MouseEvent<E, MouseEvent>) => void;
/**
 * A convenient wrapper for reading and writing search parameters via the
 * URLSearchParams interface.
 */
export declare function useSearchParams(defaultInit?: URLSearchParamsInit): readonly [URLSearchParams, (nextInit: URLSearchParamsInit, navigateOptions?: {
    replace?: boolean | undefined;
    state?: any;
} | undefined) => void];
export declare type ParamKeyValuePair = [string, string];
export declare type URLSearchParamsInit = string | ParamKeyValuePair[] | Record<string, string | string[]> | URLSearchParams;
/**
 * Creates a URLSearchParams object using the given initializer.
 *
 * This is identical to `new URLSearchParams(init)` except it also
 * supports arrays as values in the object form of the initializer
 * instead of just strings. This is convenient when you need multiple
 * values for a given key, but don't want to use an array initializer.
 *
 * For example, instead of:
 *
 *   let searchParams = new URLSearchParams([
 *     ['sort', 'name'],
 *     ['sort', 'price']
 *   ]);
 *
 * you can do:
 *
 *   let searchParams = createSearchParams({
 *     sort: ['name', 'price']
 *   });
 */
export declare function createSearchParams(init?: URLSearchParamsInit): URLSearchParams;