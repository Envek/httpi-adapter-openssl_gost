OpenSSL GOST adapter for [HTTPI]
================================

This gem allows to perform HTTP requests over secure connections, that requires russian GOST cryptoalgorithms to be used.
It allows to use client certificate and private key for authentication.

**WARNING!** This gem is kind of «last chance software». It uses `openssl s_client` command to perform requests.
As it's command for debug and testing purposes only, it's slow and unreliable. Use at your own risk only if nothing else is working for you (as it for me).

## Installation

### OpenSSL installation and configuration

You need to install OpenSSL 1.0.0 or newer (OpenSSL 1.0.1 or newer is better) with GOST engine installed (it's bundled starting from 1.0.0).

Usually in modern Lunux distributions it's installed already (at least in Ubuntu 12.04).
Mac OS X users should install it through Homebrew or MacPorts: `brew install openssl`

In `/etc/ssl/openssl.cnf` (`/usr/local/etc/openssl/openssl.cnf` for Mac OS X) add next line to _the very beginning of file_:

    openssl_conf = openssl_def

Add next lines to _the very end of file_:

    [openssl_def]
    engines = engine_section
    [engine_section]
    gost = gost_section
    [gost_section]
    default_algorithms = ALL
    dynamic_path = /usr/lib/x86_64-linux-gnu/openssl-1.0.0/engines/libgost.so
    engine_id = gost
    CRYPT_PARAMS = id-Gost28147-89-CryptoPro-A-ParamSet

`dynamic_path` isn't required in Mac OS X. Linux users can get it's value executing `locate libgost.so`.

After that, `openssl ciphers | tr ":" "\n" | grep GOST` should return following lines:

    GOST2001-GOST89-GOST89
    GOST94-GOST89-GOST89

### Gem installation

Add this line to your application's Gemfile:

    gem 'httpi-adapter-openssl_gost'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install httpi-adapter-openssl_gost

## Usage

```ruby
require 'httpi/adapter/openssl_gost'
request = HTTPI::Request.new
request.url = 'https://example.com/'
HTTPI.get(request, :openssl_gost)
```

Or you can specify it as default adapter for all requests:

```ruby
require 'httpi/adapter/openssl_gost'
HTTPI.adapter :openssl_gost
```

If you need to specify client credentials (certificate and private key),
pass file paths to `cert_file=` and `cert_key_file=` methods of the `request.auth.ssl`:

```ruby
request.auth.ssl.cert_file     = '/full/path/to/client.crt'
request.auth.ssl.cert_key_file = '/full/path/to/client.pem'
```

### Usage with savon

You need to use custom branches of [savon] and [wasabi] until next pull requests are not merged in:
 1. [savonrb/wasabi#44](https://github.com/savonrb/wasabi/issues/44)
 2. [savonrb/savon#566](https://github.com/savonrb/savon/pull/566):

Place in your Gemfile:

```ruby
gem 'wasabi', github: 'Envek/wasabi', branch: 'specify_adapter'
gem 'savon',  github: 'Envek/savon',  branch: 'specify_adapter'
```

Specify `:adapter` in savon client global options:

```ruby
require 'httpi/adapter/openssl_gost'
soap_client = Savon.client(
  wsdl:              'https://service-requiring-gost.ru/service?wsdl',
  ssl_cert_file:     '/full/path/to/client.crt',
  ssl_cert_key_file: '/full/path/to/client.pem',
  adapter:           :openssl_gost,
)
```

And use it as usual:

```ruby
soap_client.call(:method, message: {foo: 1})
```

## Contributing

1. Fork it ( https://github.com/Envek/httpi-adapter-openssl_gost/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

[HTTPI]:  https://github.com/savonrb/httpi
[savon]:  https://github.com/savonrb/savon
[wasabi]: https://github.com/savonrb/wasabi
