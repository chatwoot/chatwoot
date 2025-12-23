## 0.2.3 (2023-04-02)

- Added support for dimensions to model generator

## 0.2.2 (2022-07-13)

- Added support for configurable attribute name
- Added support for multiple attributes per model

## 0.2.1 (2021-12-15)

- Added support for Active Record 7

## 0.2.0 (2021-04-21)

- Added support for pgvector
- Added `normalize` option
- Made `dimensions` optional
- Raise an error if `nearest_neighbors` already defined
- Raise an error for non-finite values
- Fixed NaN with zero vectors and cosine distance

Breaking changes

- The `distance` option has been moved from `has_neighbors` to `nearest_neighbors`, and there is no longer a default

## 0.1.2 (2021-02-21)

- Added `nearest_neighbors` scope

## 0.1.1 (2021-02-16)

- Fixed `Could not dump table` error

## 0.1.0 (2021-02-15)

- First release
