export as namespace URLToolkit;

export type URLParts = {
  scheme: string;
  netLoc: string;
  path: string;
  params: string;
  query: string;
  fragment: string;
};

export function buildAbsoluteURL(
  baseURL: string,
  relativeURL: string,
  opts?: { alwaysNormalize?: boolean }
): string;

export function parseURL(url: string): URLParts | null;

export function normalizePath(path: string): string;

export function buildURLFromParts(parts: URLParts): string;
