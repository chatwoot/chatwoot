---
name: swr
description: Guidelines for using SWR (stale-while-revalidate) React Hooks for efficient data fetching, caching, and revalidation
---

# SWR Best Practices

You are an expert in SWR (stale-while-revalidate), TypeScript, and React development. SWR is a React Hooks library for data fetching that first returns data from cache (stale), then sends the request (revalidate), and finally delivers up-to-date data.

## Core Principles

- Use SWR for all client-side data fetching
- Leverage automatic caching and revalidation
- Minimize boilerplate with SWR's built-in state management
- Implement proper error handling and loading states
- Use TypeScript for full type safety

## Key Features

- **Stale-While-Revalidate**: Returns cached data immediately, then revalidates in background
- **Automatic Revalidation**: On mount, window focus, and network reconnection
- **Request Deduplication**: Multiple components using same key share one request
- **Built-in Caching**: Zero-configuration caching with smart invalidation
- **Minimal API**: Simple hook-based interface

## Project Structure

```
src/
  hooks/
    swr/
      useUser.ts
      usePosts.ts
      useProducts.ts
  lib/
    fetcher.ts           # Global fetcher configuration
  providers/
    SWRProvider.tsx      # SWR configuration provider
  types/
    api.ts               # API response types
```

## Setup and Configuration

### Global Configuration

```typescript
// providers/SWRProvider.tsx
import { SWRConfig } from 'swr';

const fetcher = async (url: string) => {
  const res = await fetch(url);

  if (!res.ok) {
    const error = new Error('An error occurred while fetching data.');
    throw error;
  }

  return res.json();
};

export function SWRProvider({ children }: { children: React.ReactNode }) {
  return (
    <SWRConfig
      value={{
        fetcher,
        revalidateOnFocus: true,
        revalidateOnReconnect: true,
        shouldRetryOnError: true,
        errorRetryCount: 3,
        dedupingInterval: 2000,
      }}
    >
      {children}
    </SWRConfig>
  );
}
```

### Custom Fetcher

```typescript
// lib/fetcher.ts
export async function fetcher<T>(url: string): Promise<T> {
  const response = await fetch(url, {
    headers: {
      'Content-Type': 'application/json',
    },
  });

  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }

  return response.json();
}

// With authentication
export async function authFetcher<T>(url: string): Promise<T> {
  const token = getAuthToken();

  const response = await fetch(url, {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }

  return response.json();
}
```

## Basic Usage

### useSWR Hook

The `useSWR` hook accepts three parameters:
- **key**: A unique string identifier for the request (like a URL)
- **fetcher**: An async function that fetches the data
- **options**: Configuration options

```typescript
import useSWR from 'swr';

interface User {
  id: string;
  name: string;
  email: string;
}

function useUser(userId: string) {
  const { data, error, isLoading, isValidating, mutate } = useSWR<User>(
    userId ? `/api/users/${userId}` : null,
    fetcher
  );

  return {
    user: data,
    isLoading,
    isError: !!error,
    isValidating,
    mutate,
  };
}
```

### Conditional Fetching

Pass `null` or a falsy value as key to conditionally skip fetching:

```typescript
// Only fetch when userId is available
const { data } = useSWR(userId ? `/api/users/${userId}` : null, fetcher);

// Using a function for dynamic keys
const { data } = useSWR(() => `/api/users/${userId}`, fetcher);
```

## Revalidation Strategies

### Automatic Revalidation

SWR automatically revalidates data in three cases:
1. Component is mounted (even with cached data)
2. Window gains focus
3. Browser regains network connection

```typescript
// Disable specific revalidation behaviors
const { data } = useSWR('/api/data', fetcher, {
  revalidateOnFocus: false,
  revalidateOnReconnect: false,
  revalidateOnMount: true,
});
```

### Manual Revalidation

```typescript
import { useSWRConfig } from 'swr';

function UpdateButton() {
  const { mutate } = useSWRConfig();

  const handleUpdate = async () => {
    // Revalidate specific key
    await mutate('/api/users');

    // Revalidate all keys matching a filter
    await mutate(
      (key) => typeof key === 'string' && key.startsWith('/api/users'),
      undefined,
      { revalidate: true }
    );
  };

  return <button onClick={handleUpdate}>Refresh</button>;
}
```

### Polling / Interval Refresh

```typescript
// Refresh every 3 seconds
const { data } = useSWR('/api/realtime', fetcher, {
  refreshInterval: 3000,
});

// Conditional polling
const { data } = useSWR('/api/realtime', fetcher, {
  refreshInterval: isVisible ? 1000 : 0,
});
```

## Mutation Patterns

### Optimistic Updates

```typescript
import useSWR, { useSWRConfig } from 'swr';

function useUpdateUser() {
  const { mutate } = useSWRConfig();

  const updateUser = async (userId: string, newData: Partial<User>) => {
    // Optimistic update
    await mutate(
      `/api/users/${userId}`,
      async (currentData: User | undefined) => {
        // Update API
        const updated = await fetch(`/api/users/${userId}`, {
          method: 'PATCH',
          body: JSON.stringify(newData),
        }).then(r => r.json());

        return updated;
      },
      {
        optimisticData: (current) => ({ ...current, ...newData } as User),
        rollbackOnError: true,
        populateCache: true,
        revalidate: false,
      }
    );
  };

  return { updateUser };
}
```

### Bound Mutate

```typescript
function UserProfile({ userId }: { userId: string }) {
  const { data: user, mutate } = useSWR(`/api/users/${userId}`, fetcher);

  const handleUpdate = async (newName: string) => {
    // Update local data immediately
    mutate({ ...user, name: newName }, false);

    // Send update to server
    await updateUserName(userId, newName);

    // Revalidate to ensure consistency
    mutate();
  };

  return (
    <div>
      <p>{user?.name}</p>
      <button onClick={() => handleUpdate('New Name')}>Update</button>
    </div>
  );
}
```

## Pagination

### Basic Pagination

```typescript
function usePaginatedUsers(page: number) {
  return useSWR(`/api/users?page=${page}`, fetcher, {
    keepPreviousData: true,
  });
}
```

### Infinite Loading with useSWRInfinite

```typescript
import useSWRInfinite from 'swr/infinite';

function useInfiniteUsers() {
  const getKey = (pageIndex: number, previousPageData: User[] | null) => {
    // Return null to stop fetching
    if (previousPageData && previousPageData.length === 0) return null;

    // Return key for next page
    return `/api/users?page=${pageIndex + 1}`;
  };

  const { data, error, size, setSize, isValidating } = useSWRInfinite(
    getKey,
    fetcher
  );

  const users = data ? data.flat() : [];
  const isLoadingMore = size > 0 && data && typeof data[size - 1] === 'undefined';
  const isEmpty = data?.[0]?.length === 0;
  const isReachingEnd = isEmpty || (data && data[data.length - 1]?.length < 10);

  return {
    users,
    isLoadingMore,
    isReachingEnd,
    loadMore: () => setSize(size + 1),
  };
}
```

### Cursor-Based Pagination

```typescript
import useSWRInfinite from 'swr/infinite';

function useCursorPagination() {
  const getKey = (pageIndex: number, previousPageData: any) => {
    if (previousPageData && !previousPageData.nextCursor) return null;

    if (pageIndex === 0) return '/api/items';

    return `/api/items?cursor=${previousPageData.nextCursor}`;
  };

  return useSWRInfinite(getKey, fetcher);
}
```

## Error Handling

### Component-Level Error Handling

```typescript
function UserProfile({ userId }: { userId: string }) {
  const { data, error, isLoading } = useSWR(`/api/users/${userId}`, fetcher);

  if (isLoading) return <Skeleton />;

  if (error) {
    return (
      <ErrorMessage
        message="Failed to load user profile"
        retry={() => mutate(`/api/users/${userId}`)}
      />
    );
  }

  return <ProfileCard user={data} />;
}
```

### Global Error Handler

```typescript
<SWRConfig
  value={{
    onError: (error, key) => {
      if (error.status !== 403 && error.status !== 404) {
        // Send error to tracking service
        reportError(error, key);
      }
    },
  }}
>
  <App />
</SWRConfig>
```

## Prefetching

```typescript
import { preload } from 'swr';

// Prefetch data before component renders
function prefetchUser(userId: string) {
  preload(`/api/users/${userId}`, fetcher);
}

// Usage: Call on hover or route change
function UserLink({ userId }: { userId: string }) {
  return (
    <Link
      to={`/users/${userId}`}
      onMouseEnter={() => prefetchUser(userId)}
    >
      View Profile
    </Link>
  );
}
```

## Key Conventions

1. Use SWR for client-side data fetching with minimal configuration
2. Implement conditional rendering for loading states and error messages
3. Validate data to ensure expected format and handle errors gracefully
4. Use prefetching to improve performance before users request data
5. Leverage automatic revalidation for real-time data freshness
6. Use `useSWRInfinite` for paginated and infinite scroll patterns

## Integration with Next.js

```typescript
// For server-side data, use getServerSideProps or getStaticProps
// For client-side caching and revalidation, use SWR

// pages/user/[id].tsx
export async function getStaticProps({ params }) {
  const user = await fetchUser(params.id);
  return { props: { fallback: { [`/api/users/${params.id}`]: user } } };
}

export default function UserPage({ fallback }) {
  return (
    <SWRConfig value={{ fallback }}>
      <UserProfile />
    </SWRConfig>
  );
}
```

## Anti-Patterns to Avoid

- Do not use `useEffect` for data fetching when SWR can handle it
- Do not ignore error states - always provide user feedback
- Do not forget to handle loading states appropriately
- Do not use polling when WebSocket or SSE would be more efficient
- Do not skip conditional fetching for dependent data
- Do not ignore TypeScript types for fetched data
