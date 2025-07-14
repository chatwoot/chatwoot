/**
Convert Windows backslash paths to slash paths: `foo\\bar` ➔ `foo/bar`.

[Forward-slash paths can be used in Windows](http://superuser.com/a/176395/6877) as long as they're not extended-length paths and don't contain any non-ascii characters.

@param path - A Windows backslash path.
@returns A path with forward slashes.

@example
```
import path from 'path';
import slash from 'slash';

const string = path.join('foo', 'bar');
// Unix    => foo/bar
// Windows => foo\\bar

slash(string);
// Unix    => foo/bar
// Windows => foo/bar
```
*/
export default function slash(path: string): string;
