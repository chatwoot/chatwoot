# Running Puma in Rails Development Mode

## "Loopback requests" 

Be cautious of "loopback requests," where a Rails application executes a request to a server that, in turn, results in another request back to the same Rails application before the first request completes. Having a loopback request will trigger [Rails' load interlock](https://guides.rubyonrails.org/threading_and_code_execution.html#load-interlock) mechanism. The load interlock mechanism prevents a thread from using Rails autoloading mechanism to load constants while the application code is still running inside another thread.

This issue only occurs in the development environment as Rails' load interlock is not used in production environments. Although we're not sure, we believe this issue may not occur with the new `zeitwerk` code loader.

### Solutions

#### 1. Bypass Rails' load interlock with `.permit_concurrent_loads`

Wrap the first request inside a block that will allow concurrent loads: [`ActiveSupport::Dependencies.interlock.permit_concurrent_loads`](https://guides.rubyonrails.org/threading_and_code_execution.html#permit-concurrent-loads). Anything wrapped inside the `.permit_concurrent_loads` block will bypass the load interlock mechanism, allowing new threads to access the Rails environment and boot properly. 

###### Example 

```ruby
response = ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
  # Your HTTP request code here. For example:
  Faraday.post url, data: 'foo'
end

do_something_with response
```

####  2. Use multiple processes on Puma

Alternatively, you may also enable multiple (single-threaded) workers on Puma. By doing so, you are sidestepping the problem by creating multiple processes rather than new threads. However, this workaround is not ideal because debugging tools such as [byebug](https://github.com/deivid-rodriguez/byebug/issues/487) and [pry](https://github.com/pry/pry/issues/2153), work poorly with any multi-process web server. 
