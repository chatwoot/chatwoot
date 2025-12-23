The [unix signal](https://en.wikipedia.org/wiki/Unix_signal) is a method of sending messages between [processes](https://en.wikipedia.org/wiki/Process_(computing)). When a signal is sent, the operating system interrupts the target process's normal flow of execution. There are standard signals that are used to stop a process, but there are also custom signals that can be used for other purposes. This document is an attempt to list all supported signals that Puma will respond to. In general, signals need only be sent to the master process of a cluster.

## Sending Signals

If you are new to signals, it can be helpful to see how they are used. When a process starts in a *nix-like operating system, it will have a [PID - or process identifier](https://en.wikipedia.org/wiki/Process_identifier) that can be used to send signals to the process. For demonstration, we will create an infinitely running process by tailing a file:

```sh
$ echo "foo" >> my.log
$ irb
> pid = Process.spawn 'tail -f my.log'
```

From here, we can see that the tail process is running by using the `ps` command:

```sh
$ ps aux | grep tail
schneems        87152   0.0  0.0  2432772    492 s032  S+   12:46PM   0:00.00 tail -f my.log
```

You can send a signal in Ruby using the [Process module](https://www.ruby-doc.org/core-2.1.1/Process.html#kill-method):

```
$ irb
> puts pid
=> 87152
Process.detach(pid) # https://ruby-doc.org/core-2.1.1/Process.html#method-c-detach
Process.kill("TERM", pid)
```

Now you will see via `ps` that there is no more `tail` process. Sometimes when referring to signals, the `SIG` prefix will be used. For example, `SIGTERM` is equivalent to sending `TERM` via `Process.kill`.

## Puma Signals

Puma cluster responds to these signals:

- `TTIN` increment the worker count by 1
- `TTOU` decrement the worker count by 1
- `TERM` send `TERM` to worker. The worker will attempt to finish then exit.
- `USR2` restart workers. This also reloads the Puma configuration file, if there is one.
- `USR1` restart workers in phases, a rolling restart. This will not reload the configuration file.
- `HUP ` reopen log files defined in stdout_redirect configuration parameter. If there is no stdout_redirect option provided, it will behave like `INT`
- `INT ` equivalent of sending Ctrl-C to cluster. Puma will attempt to finish then exit.
- `CHLD`
- `URG ` refork workers in phases from worker 0 if `fork_workers` option is enabled.
- `INFO` print backtraces of all puma threads

## Callbacks order in case of different signals

### Start application

```
puma configuration file reloaded, if there is one
* Pruning Bundler environment
puma configuration file reloaded, if there is one

before_fork
on_worker_fork
after_worker_fork

Gemfile in context

on_worker_boot

Code of the app is loaded and running
```

### Send USR2

```
on_worker_shutdown
on_restart

puma configuration file reloaded, if there is one

before_fork
on_worker_fork
after_worker_fork

Gemfile in context

on_worker_boot

Code of the app is loaded and running
```

### Send USR1

```
on_worker_shutdown
on_worker_fork
after_worker_fork

Gemfile in context

on_worker_boot

Code of the app is loaded and running
```
