# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.5.0] - 2025-06-01
### Added
- Handle filtering tools and resources [#85 @yjacquin](https://github.com/yjacquin/fast-mcp/pull/85)
- Support for resource templates 🥳 Big thanks to @danielcooper for the contribution [#84 co-authored by @danielcooper and @yjacquin](https://github.com/yjacquin/fast-mcp/pull/84)
- Possibility to authorize requests before tool calls [#79 @EuanEdgar](https://github.com/yjacquin/fast-mcp/pull/79)
- Possibility to read request headers in tool calls [#78 @EuanEdgar](https://github.com/yjacquin/fast-mcp/pull/78)
### Changed
- Bump Dependencies [#86 @aothelal](https://github.com/yjacquin/fast-mcp/pull/86)
- ⚠️ Resources are now stateless, meaning that in-memory resources won't work anymore, they require an external data source such as database, file to read and write too, etc. This was needed for a refactoring of the resource class for the [resource template PR](https://github.com/yjacquin/fast-mcp/pull/84)
### Fixed
- Stop overriding log level to info [#91 @yjacquin](https://github.com/yjacquin/fast-mcp/pull/91)
- Properly handle ping request responses from clients [#89 @yjacquin](https://github.com/yjacquin/fast-mcp/pull/89)
- Add Thread Safety to RackTransport sse_clients [#82 @Kevin-K](https://github.com/yjacquin/fast-mcp/pull/82)

## [1.4.0] - 2025-05-10
### Added
- Conditionnally hidden properties for tool calls (#70) [#70 @yjacquin](https://github.com/yjacquin/fast-mcp/pull/70)
- Metadata to tool call results (#69) [#69 @yjacquin](https://github.com/yjacquin/fast-mcp/pull/69)
- Link to official Discord Server in README.md

## [1.3.2] - 2025-05-08
### Changed
- Logs are now less verbose by default [#64 @yjacquin](https://github.com/yjacquin/fast-mcp/pull/64)
### Fixed
- Fix undefined method `call' for an instance of String error log [#61 @radwo](https://github.com/yjacquin/fast-mcp/pull/61)

## [1.3.1] - 2025-04-30
### Fixed
-  Allow ipv4 mapped to ipv6 (#56) [#56 @josevalim](https://github.com/yjacquin/fast-mcp/pull/56)
-  Add items to array (#55) [#55 @josevalim](https://github.com/yjacquin/fast-mcp/pull/56)
-  Ping is a regular message event (#54) [#56 @josevalim](https://github.com/yjacquin/fast-mcp/pull/56)

## [1.3.0] - 2025-04-28
### Added
- Added automatic forwarding of query params from to the messages endpoint [@yjacquin](https://github.com/yjacquin/fast-mcp/commit/011d968ac982d0b0084f7753dcac5789f66339ee)

### Fixed
- Declare rack as an explicit dependency [#49 @subelsky](https://github.com/yjacquin/fast-mcp/pull/49)
- Fix notifications/initialized response [#51 @yjacquin](https://github.com/yjacquin/fast-mcp/pull/51)

## [1.2.0] - 2025-04-21
### Added
- Security enhancement: Bing only to localhost by default [#44 @yjacquin](https://github.com/yjacquin/fast-mcp/pull/44)
- Prevent AuthenticatedRackMiddleware from blocking other rails routes[#35 @JulianPasquale](https://github.com/yjacquin/fast-mcp/pull/35)
- Stop Forcing reconnections after 30 pings [#42 @zoedsoupe](https://github.com/yjacquin/fast-mcp/pull/42)


## [1.1.0] - 2025-04-13
### Added
- Security enhancement: Added DNS rebinding protection by validating Origin headers [#32 @yjacquin](https://github.com/yjacquin/fast-mcp/pull/32/files)
- Added configuration options for allowed origins in rack middleware [#32 @yjacquin](https://github.com/yjacquin/fast-mcp/pull/32/files)
- Allow to change the SSE and Messages route [#23 @pedrofurtado](https://github.com/yjacquin/fast-mcp/pull/23)
- Fix invalid return value when processing notifications/initialized request [#31 @abMatGit](https://github.com/yjacquin/fast-mcp/pull/31)


## [1.0.0] - 2025-03-30

### Added
- Rails integration improvements via enhanced Railtie support
- Automatic tool and resource registration in Rails applications
- Extended Rails autoload paths for tools and resources directories
- Sample generator templates for resources and tools
- MCP Client configuration documentation as reported by [#8 @sivag-csod](https://github.com/yjacquin/fast-mcp/issues/8)
- Example Ruby on Rails app in the documentation
- `FastMcp.server` now exposes the MCP server to apps that may need it to access resources
- Automated Github Releases through Github Workflow

### Fixed
- Fixed bug with Rack middlewares not being initialized properly.
- Fixed bug with STDIO logging preventing a proper connection with clients [# 11 @cs3b](https://github.com/yjacquin/fast-mcp/issues/11)
- Fixed Rails SSE streaming detection and handling
- Improved error handling in client reconnection scenarios
- Namespace consistency correction (FastMCP -> FastMcp) throughout the codebase

### Improved
- ⚠️ [Breaking] Resource content declaration changes
  - Now resources implement `content` over `default_content`
  - `content` is dynamically called when calling a resource, this implies we can declare dynamic resource contents like:
  ```ruby
  class HighestScoringUsersResource < FastMcp::Resource
  ...
    def content
      User.order(score: :desc).last(5).map(&:as_json)
    end
  end
  ```
- More robust SSE connection lifecycle management
- Optimized test suite with faster execution times
- Better logging for debugging connection issues
- Documentation had outdated examples

## [0.1.0] - 2025-03-12

### Added

- Initial release of the Fast MCP library
- FastMcp::Tool class with multiple definition styles
- FastMcp::Server class with STDIO transport and HTTP / SSE transport
- Rack Integration with authenticated and standard middleware options
- Resource management with subscription capabilities
- Binary resource support
- Examples with STDIO Transport, HTTP & SSE, Rack app
- Initialize lifecycle with capabilities
- Comprehensive test suite with RSpec
