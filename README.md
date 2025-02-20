# Serve

[![Actions Status](https://github.com/quexpl/serve/workflows/CI/badge.svg)](https://github.com/quexpl/serve/actions?query=workflow%3ACI)
[![Hex pm](https://img.shields.io/hexpm/v/serve.svg?style=flat)](https://hex.pm/packages/serve)
[![Hexdocs badge](https://img.shields.io/badge/docs-hexdocs-purple)](https://hexdocs.pm/serve)


**Serve** is escript to quickly start an HTTP server, similar to quick-start solutions available in other languages:

```shell
$ php -S localhost:8080
$ ruby -run -e httpd . -p 8080
$ python3 -m http.server 8080
```

With **Serve**, you can quickly start an HTTP server:

```shell
$ serve /var/www/html
[info] Serving /var/www/html with Cowboy 2.13.0 at http://127.0.0.1:4444
```

## Installation

To install from Hex, run:

    $ mix escript.install hex serve

To build and install it locally run:

    $ mix install

it's a alias for:

    $ mix do deps.get, escript.build, escript.install

> Note: For convenience, consider adding `~/.mix/escripts` directory to your `$PATH` environment variable.
> If you are using [asdf](https://github.com/asdf-vm/asdf) Whenever you install a new escript with `mix escript.install` you need to `asdf reshim elixir` in order to create shims for it.

If you want to uninstall Serve simply run:

    $ mix escript.uninstall serve

## Options

### Comand line options

You can pass options directly to `serve`

- `-p`, `--port` - Specify the port to listen on (default: `4444`).
- `-o`, `--open` - Open the browser automatically.
- `-n`, `--no-index` - Disable directory listing.
- `-v`, `--version` - Shows Serve version.
- `-h`, `--help` - Shows Serve usage information.

```shell
$ serve --port 3000
```

### Environment variables

Serve also supports environment variables for all options. Simply use env with `MIX_SERVE_` prefix.

```shell
$ MIX_SERVE_PORT=3000 serve
```

You can also add exports to yours profile file, for example:
```
export MIX_SERVE_PORT=8000
export MIX_SERVE_OPEN=true
export MIX_SERVE_NO_INDEX=true
```

## Arguments

Serve accepts one argument: the directory to be served. If no directory is specified, the current working directory is used.

```shell
$ pwd
/var/www/html/my_website
$ serve
[info] Serving  /var/www/html/my_website with Cowboy 2.13.0 at http://localhost:4444
```

```shell
$ mix docs
Generating docs...
View "html" docs at "doc/index.html"
View "epub" docs at "doc/serve.epub"
$ serve s doc
[info] Serving  /home/quex/workspace/serve/doc with Cowboy 2.13.0 at http://localhost:4444
```

## Features

- dark mode
- directory index

![dark mode](https://github.com/quexpl/serve/blob/main/images/index-dark.jpg?raw=true)
![directory index](https://github.com/quexpl/serve/blob/main/images/index.jpg?raw=true)
![not found](https://github.com/quexpl/serve/blob/main/images/404.jpg?raw=true)

## Security

Although Serve uses the robust Cowboy HTTP server, it is not intended to be a production-ready web server. It only supports the HTTP protocol and listens on the loopback interface.