import { ReactNode } from 'react';
import * as R from 'react-router-dom';

export declare const BaseLocationProvider: typeof R.Router;
export declare const DEEPLY_EQUAL: unique symbol;
export declare const Link: {
	({ to, children, ...rest }: LinkProps): JSX.Element;
	displayName: string;
};
export declare const Location: {
	({ children }: LocationProps): JSX.Element;
	displayName: string;
};
export declare const LocationProvider: typeof R.BrowserRouter;
export declare const Match: {
	({ children, path: targetPath, startsWith }: MatchProps): JSX.Element;
	displayName: string;
};
export declare const Route: {
	({ path, children, startsWith, hideOnly }: RouteProps): JSX.Element;
	displayName: string;
};
export declare const buildArgsParam: (initialArgs: Args, args: Args) => string;
export declare const deepDiff: (value: any, update: any) => any;
export declare const getMatch: (current: string, target: string, startsWith?: any) => Match | null;
export declare const parsePath: (path: string | undefined) => StoryData;
export declare const queryFromLocation: (location: Partial<Location>) => Query;
export declare const queryFromString: (s: string) => Query;
export declare const stringifyQuery: (query: Query) => string;
export declare const useNavigate: () => (to: string | number, { plain, ...options }?: any) => void;
export declare type Match = {
	path: string;
};
export declare type NavigateOptions = ReturnType<typeof R.useNavigate> & {
	plain?: boolean;
};
export declare type RenderData = Pick<RouterData, "location"> & Other;
export declare type RouterData = {
	location: Partial<Location>;
	navigate: ReturnType<typeof useNavigate>;
} & Other;
export interface Args {
	[key: string]: any;
}
export interface LinkProps {
	to: string;
	children: ReactNode;
}
export interface LocationProps {
	children: (renderData: RenderData) => ReactNode;
}
export interface MatchProps {
	path: string;
	startsWith: boolean;
	children: (matchingData: MatchingData) => ReactNode;
}
export interface MatchingData {
	match: null | {
		path: string;
	};
}
export interface Other extends StoryData {
	path: string;
	singleStory?: boolean;
}
export interface Query {
	[key: string]: any;
}
export interface RouteProps {
	path: string;
	startsWith?: boolean;
	hideOnly?: boolean;
	children: ReactNode;
}
export interface StoryData {
	viewMode?: string;
	storyId?: string;
	refId?: string;
}

export {};
