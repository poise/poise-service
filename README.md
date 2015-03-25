# Poise-Service Cookbook

[![Build Status](https://img.shields.io/travis/poise/poise-service.svg)](https://travis-ci.org/poise/poise-service)
[![Gem Version](https://img.shields.io/gem/v/poise-service.svg)](https://rubygems.org/gems/poise-service)
[![Cookbook Version](https://img.shields.io/cookbook/v/poise-service.svg)](https://supermarket.chef.io/cookbooks/poise-service)
[![Coverage](https://img.shields.io/codecov/c/github/poise/poise-service.svg)](https://codecov.io/github/poise/poise-service)
[![Gemnasium](https://img.shields.io/gemnasium/poise/poise-service.svg)](https://gemnasium.com/poise/poise-service)
[![License](https://img.shields.io/badge/license-Apache_2-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

A [Chef](https://www.chef.io/) cookbook to provide a unified interface for
services.

### What is poise-service?

Poise-service is a tool for developers of "library cookbooks" to define a
service without forcing the end-user of the library to adhere to their choice of
service management framework. The `poise_service` resource represents an
abstract service to be run, which can then be customized by node attributes and
the `poise_service_options` resource. This is a technique called [dependency
injection](https://en.wikipedia.org/wiki/Dependency_injection), and allows a
measure of decoupling between the library and application cookbooks.

### How is this different from the built-in service resource?

Chef includes a `service` resource which allows interacting with certain
service management frameworks such as SysV, Upstart, and systemd.
`poise-service` goes further in that it actually generates the configuration
files needed for the requested service management framework, as well as offering
a dependency injection system for application cookbooks to customize which
framework is used.

### What service management frameworks are supported?

* SysV (aka /etc/init.d)
* Upstart
* systemd
* [Runit](https://github.com/poise/poise-service-runit)
* *Supervisor (coming soon!)*

## Resources

### `poise_service`

The `poise_service` resource is the abstract definition of a service.

```ruby
poise_service 'myapp' do
  command 'myapp --serve'
  user 'myuser'
  environment RAILS_ENV: 'production'
end
```

#### Actions

* `:enable` – Create, enable and start the service. *(default)*
* `:disable` – Stop, disable, and destroy the service.
* `:start` – Start the service.
* `:stop` – Stop the service.
* `:restart` – Stop and then start the service.
* `:reload` – Send the configured reload signal to the service.

#### Attributes

* `service_name` – Name of the service. *(name attribute)*
* `command` – Command to run for the service. This command must stay in the
  foreground and not daemonize itself. *(required)*
* `user` – User to run the service as. See
  [`poise_service_user`](#poise_service_user) for any easy way to create service
   users. *(default: root)*
* `directory` – Working directory for the service. *(default: home directory for
  user, or / if not found)*
* `environment` – Environment variables for the service.
* `stop_signal` – Signal to use to stop the service. Some systems will fall back
  to SIGKILL if this signal fails to stop the process. *(default: TERM)*
* `reload_signal` – Signal to use to reload the service. *(default: HUP)*
* `restart_on_update` – If true, the service will be restarted if the service
  definition or configuration changes. If `'immediately'`, the notification will
  happen in immediate mode. *(default: true)*

#### Service Options

The `poise-service` library offers an additional way to pass configuration
information to the final service called "options". Options are key/value pairs
that are passed down to the service provider and can be used to control how it
creates and manages the service. These can be set in the `poise_service`
resource using the `options` method, in node attributes or via the
`poise_service_options` resource. The options from all sources are merged
together into a single hash based.

When setting options in the resource you can either set them for all providers:

```ruby
poise_service 'myapp' do
  command 'myapp --serve'
  options status_port: 8000
end
```

or for a single provider:

```ruby
poise_service 'myapp' do
  command 'myapp --serve'
  options :systemd, after_target: 'network'
end
```

Setting via node attributes is generally how an end-user or application cookbook
will set options to customize services in the library cookbooks they are using.
You can set options for all services or for a single service, by service name
or by resource name:

```ruby
# Global, for all services.
override['poise-service']['options']['after_target'] = 'network'
# Single service.
override['poise-service']['myapp']['template'] = 'myapp.erb'
```

The `poise_service_options` resource is also available to set node attributes
for a specific service in a DSL-friendly way:

```ruby
poise_service_options 'myapp' do
  template 'myapp.erb'
  restart_on_update false
end
```

Unlike resource attributes, service options can be different for each provide.
Not all providers support the same options so make sure to the check the
documentation for each provider to see what options the use.

### `poise_service_options`

The `poise_service_options` resource allows setting per-service options in a
DSL-friendly way. See [the Service Options](#service-options) section for more
information about service options overall.

```ruby
poise_service_options 'myapp' do
  template 'myapp.erb'
  restart_on_update false
end
```

#### Actions

* `:run` – Apply the service options. *(default)*

#### Attributes

* `service_name` – Name of the service. *(name attribute)*
* `for_provider` – Provider to set options for. If set, the resource must be
  defined and reachable before the `poise_service_options` resource.

All other attribute keys will be used as options data.

### `poise_service_user`

The `poise_service_user` resource is an easy way to create service users. It is
not required to use `poise_service`, it is only a helper.

```ruby
poise_service_user 'myapp' do
  home '/srv/myapp'
end
```

#### Actions

* `:create` – Create the user and group. *(default)*
* `:remove` – Remove the user and group.

#### Attributes

* `user` – Name of the user. *(name attribute)*
* `group` – Name of the group. Set to `false` to disable group creation. *(name attribute)*
* `uid` – UID of the user. If unspecified it will be automatically allocated.
* `gid` – GID of the group. If unspecified it will be automatically allocated.
* `home` – Home directory of the user.

## Sponsors

The Poise test server infrastructure is generously sponsored by [Rackspace](https://rackspace.com/). Thanks Rackspace!

## License

Copyright 2015, Noah Kantrowitz

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
