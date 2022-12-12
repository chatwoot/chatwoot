import * as React from "react";
import type { History, InitialEntry, Location, Path, To } from "./react-router-node_modules-history-index";
import { Action as NavigationType } from "./react-router-node_modules-history-index";
export type { Location, Path, To, NavigationType };
/**
 * A Navigator is a "location changer"; it's how you get to different locations.
 *
 * Every history instance conforms to the Navigator interface, but the
 * distinction is useful primarily when it comes to the low-level <Router> API
 * where both the location and a navigator must be provided separately in order
 * to avoid "tearing" that may occur in a suspense-enabled app if the action
 * and/or location were to be read directly from the history instance.
 */
export declare type Navigator = Omit<History, "action" | "location" | "back" | "forward" | "listen" | "block">;
interface NavigationContextObject {
    basename: string;
    navigator: Navigator;
    static: boolean;
}
declare const NavigationContext: React.Context<NavigationContextObject>;
interface LocationContextObject {
    location: Location;
    navigationType: NavigationType;
}
declare const LocationContext: React.Context<LocationContextObject>;
interface RouteContextObject {
    outlet: React.ReactElement | null;
    matches: RouteMatch[];
}
declare const RouteContext: React.Context<RouteContextObject>;
export interface MemoryRouterProps {
    basename?: string;
    children?: React.ReactNode;
    initialEntries?: InitialEntry[];
    initialIndex?: number;
}
/**
 * A <Router> that stores all entries in memory.
 *
 * @see https://reactrouter.com/docs/en/v6/api#memoryrouter
 */
export declare function MemoryRouter({ basename, children, initialEntries, initialIndex }: MemoryRouterProps): React.ReactElement;
export interface NavigateProps {
    to: To;
    replace?: boolean;
    state?: any;
}
/**
 * Changes the current location.
 *
 * Note: This API is mostly useful in React.Component subclasses that are not
 * able to use hooks. In functional components, we recommend you use the
 * `useNavigate` hook instead.
 *
 * @see https://reactrouter.com/docs/en/v6/api#navigate
 */
export declare function Navigate({ to, replace, state }: NavigateProps): null;
export interface OutletProps {
}
/**
 * Renders the child route's element, if there is one.
 *
 * @see https://reactrouter.com/docs/en/v6/api#outlet
 */
export declare function Outlet(_props: OutletProps): React.ReactElement | null;
export interface RouteProps {
    caseSensitive?: boolean;
    children?: React.ReactNode;
    element?: React.ReactElement | null;
    index?: boolean;
    path?: string;
}
export interface PathRouteProps {
    caseSensitive?: boolean;
    children?: React.ReactNode;
    element?: React.ReactElement | null;
    index?: false;
    path: string;
}
export interface LayoutRouteProps {
    children?: React.ReactNode;
    element?: React.ReactElement | null;
}
export interface IndexRouteProps {
    element?: React.ReactElement | null;
    index: true;
}
/**
 * Declares an element that should be rendered at a certain URL path.
 *
 * @see https://reactrouter.com/docs/en/v6/api#route
 */
export declare function Route(_props: PathRouteProps | LayoutRouteProps | IndexRouteProps): React.ReactElement | null;
export interface RouterProps {
    basename?: string;
    children?: React.ReactNode;
    location: Partial<Location> | string;
    navigationType?: NavigationType;
    navigator: Navigator;
    static?: boolean;
}
/**
 * Provides location context for the rest of the app.
 *
 * Note: You usually won't render a <Router> directly. Instead, you'll render a
 * router that is more specific to your environment such as a <BrowserRouter>
 * in web browsers or a <StaticRouter> for server rendering.
 *
 * @see https://reactrouter.com/docs/en/v6/api#router
 */
export declare function Router({ basename: basenameProp, children, location: locationProp, navigationType, navigator, static: staticProp }: RouterProps): React.ReactElement | null;
export interface RoutesProps {
    children?: React.ReactNode;
    location?: Partial<Location> | string;
}
/**
 * A container for a nested tree of <Route> elements that renders the branch
 * that best matches the current location.
 *
 * @see https://reactrouter.com/docs/en/v6/api#routes
 */
export declare function Routes({ children, location }: RoutesProps): React.ReactElement | null;
/**
 * Returns the full href for the given "to" value. This is useful for building
 * custom links that are also accessible and preserve right-click behavior.
 *
 * @see https://reactrouter.com/docs/en/v6/api#usehref
 */
export declare function useHref(to: To): string;
/**
 * Returns true if this component is a descendant of a <Router>.
 *
 * @see https://reactrouter.com/docs/en/v6/api#useinroutercontext
 */
export declare function useInRouterContext(): boolean;
/**
 * Returns the current location object, which represents the current URL in web
 * browsers.
 *
 * Note: If you're using this it may mean you're doing some of your own
 * "routing" in your app, and we'd like to know what your use case is. We may
 * be able to provide something higher-level to better suit your needs.
 *
 * @see https://reactrouter.com/docs/en/v6/api#uselocation
 */
export declare function useLocation(): Location;
/**
 * Returns the current navigation action which describes how the router came to
 * the current location, either by a pop, push, or replace on the history stack.
 *
 * @see https://reactrouter.com/docs/en/v6/api#usenavigationtype
 */
export declare function useNavigationType(): NavigationType;
/**
 * Returns true if the URL for the given "to" value matches the current URL.
 * This is useful for components that need to know "active" state, e.g.
 * <NavLink>.
 *
 * @see https://reactrouter.com/docs/en/v6/api#usematch
 */
export declare function useMatch<ParamKey extends string = string>(pattern: PathPattern | string): PathMatch<ParamKey> | null;
/**
 * The interface for the navigate() function returned from useNavigate().
 */
export interface NavigateFunction {
    (to: To, options?: NavigateOptions): void;
    (delta: number): void;
}
export interface NavigateOptions {
    replace?: boolean;
    state?: any;
}
/**
 * Returns an imperative method for changing the location. Used by <Link>s, but
 * may also be used by other elements to change the location.
 *
 * @see https://reactrouter.com/docs/en/v6/api#usenavigate
 */
export declare function useNavigate(): NavigateFunction;
/**
 * Returns the element for the child route at this level of the route
 * hierarchy. Used internally by <Outlet> to render child routes.
 *
 * @see https://reactrouter.com/docs/en/v6/api#useoutlet
 */
export declare function useOutlet(): React.ReactElement | null;
/**
 * Returns an object of key/value pairs of the dynamic params from the current
 * URL that were matched by the route path.
 *
 * @see https://reactrouter.com/docs/en/v6/api#useparams
 */
export declare function useParams<Key extends string = string>(): Readonly<Params<Key>>;
/**
 * Resolves the pathname of the given `to` value against the current location.
 *
 * @see https://reactrouter.com/docs/en/v6/api#useresolvedpath
 */
export declare function useResolvedPath(to: To): Path;
/**
 * Returns the element of the route that matched the current location, prepared
 * with the correct context to render the remainder of the route tree. Route
 * elements in the tree must render an <Outlet> to render their child route's
 * element.
 *
 * @see https://reactrouter.com/docs/en/v6/api#useroutes
 */
export declare function useRoutes(routes: RouteObject[], locationArg?: Partial<Location> | string): React.ReactElement | null;
/**
 * Creates a route config from a React "children" object, which is usually
 * either a `<Route>` element or an array of them. Used internally by
 * `<Routes>` to create a route config from its children.
 *
 * @see https://reactrouter.com/docs/en/v6/api#createroutesfromchildren
 */
export declare function createRoutesFromChildren(children: React.ReactNode): RouteObject[];
/**
 * The parameters that were parsed from the URL path.
 */
export declare type Params<Key extends string = string> = {
    readonly [key in Key]: string | undefined;
};
/**
 * A route object represents a logical route, with (optionally) its child
 * routes organized in a tree-like structure.
 */
export interface RouteObject {
    caseSensitive?: boolean;
    children?: RouteObject[];
    element?: React.ReactNode;
    index?: boolean;
    path?: string;
}
/**
 * Returns a path with params interpolated.
 *
 * @see https://reactrouter.com/docs/en/v6/api#generatepath
 */
export declare function generatePath(path: string, params?: Params): string;
/**
 * A RouteMatch contains info about how a route matched a URL.
 */
export interface RouteMatch<ParamKey extends string = string> {
    /**
     * The names and values of dynamic parameters in the URL.
     */
    params: Params<ParamKey>;
    /**
     * The portion of the URL pathname that was matched.
     */
    pathname: string;
    /**
     * The portion of the URL pathname that was matched before child routes.
     */
    pathnameBase: string;
    /**
     * The route object that was used to match.
     */
    route: RouteObject;
}
/**
 * Matches the given routes to a location and returns the match data.
 *
 * @see https://reactrouter.com/docs/en/v6/api#matchroutes
 */
export declare function matchRoutes(routes: RouteObject[], locationArg: Partial<Location> | string, basename?: string): RouteMatch[] | null;
/**
 * Renders the result of `matchRoutes()` into a React element.
 */
export declare function renderMatches(matches: RouteMatch[] | null): React.ReactElement | null;
/**
 * A PathPattern is used to match on some portion of a URL pathname.
 */
export interface PathPattern {
    /**
     * A string to match against a URL pathname. May contain `:id`-style segments
     * to indicate placeholders for dynamic parameters. May also end with `/*` to
     * indicate matching the rest of the URL pathname.
     */
    path: string;
    /**
     * Should be `true` if the static portions of the `path` should be matched in
     * the same case.
     */
    caseSensitive?: boolean;
    /**
     * Should be `true` if this pattern should match the entire URL pathname.
     */
    end?: boolean;
}
/**
 * A PathMatch contains info about how a PathPattern matched on a URL pathname.
 */
export interface PathMatch<ParamKey extends string = string> {
    /**
     * The names and values of dynamic parameters in the URL.
     */
    params: Params<ParamKey>;
    /**
     * The portion of the URL pathname that was matched.
     */
    pathname: string;
    /**
     * The portion of the URL pathname that was matched before child routes.
     */
    pathnameBase: string;
    /**
     * The pattern that was used to match.
     */
    pattern: PathPattern;
}
/**
 * Performs pattern matching on a URL pathname and returns information about
 * the match.
 *
 * @see https://reactrouter.com/docs/en/v6/api#matchpath
 */
export declare function matchPath<ParamKey extends string = string>(pattern: PathPattern | string, pathname: string): PathMatch<ParamKey> | null;
/**
 * Returns a resolved path object relative to the given pathname.
 *
 * @see https://reactrouter.com/docs/en/v6/api#resolvepath
 */
export declare function resolvePath(to: To, fromPathname?: string): Path;
/** @internal */
export { NavigationContext as UNSAFE_NavigationContext, LocationContext as UNSAFE_LocationContext, RouteContext as UNSAFE_RouteContext };