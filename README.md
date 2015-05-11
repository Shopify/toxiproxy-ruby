# toxiproxy-ruby

[Toxiproxy](https://github.com/shopify/toxiproxy) is a proxy to simulate network
and system conditions. The Ruby API aims to make it simple to write tests that
ensure your application behaves appropriately under harsh conditions. Before you
can use the Ruby library, you need to read the [Usage section of the Toxiproxy
README](https://github.com/shopify/toxiproxy#usage).

```
gem install toxiproxy
```

Make sure the Toxiproxy server is already running.

For more information about Toxiproxy and the available toxics, see the [Toxiproxy
documentation](https://github.com/shopify/toxiproxy)

## Usage

The Ruby client communicates with the Toxiproxy daemon via HTTP.

For example, to simulate 1000ms latency on a database server you can use the
`latency` toxic with the `latency` argument (see the Toxiproxy project for a
list of all toxics):

```ruby
Toxiproxy[:mysql_master].downstream(:latency, latency: 1000).apply do
  Shop.first # this took at least 1s
end
```

You can also take an endpoint down for the duration of a block at the TCP level:

```ruby
Toxiproxy[:mysql_master].down do
  Shop.first # this'll raise
end
```

If you want to simulate all your Redis instances being down:

```ruby
Toxiproxy[/redis/].down do
  # any redis call will fail
end
```

If you want to simulate that your cache server is slow at incoming network
(upstream), but fast at outgoing (downstream), you can apply a toxic to just the
upstream:

```ruby
Toxiproxy[:cache].upstream(:latency, latency: 1000).apply do
  Cache.get(:omg) # will take at least a second
end
```

You can apply many toxics to many connections:

```ruby
Toxiproxy[/redis/].upstream(:slow_close, delay: 100).downstream(:latency, jitter: 300).apply do
  # all redises are now slow at responding and closing
end
```

See the [Toxiproxy README](https://github.com/shopify/toxiproxy#Toxics) for a
list of toxics.

## Populate

To populate Toxiproxy pass the proxy configurations to `Toxiproxy#populate`:

```ruby
Toxiproxy.populate([{
  name: "mysql_master",
  listen: "localhost:21212",
  upstream: "localhost:3306",
},{
  name: "mysql_read_only",
  listen: "localhost:21213",
  upstream: "localhost:3306",
})
```

This will create the proxies passed, or replace the proxies if they already exist in Toxiproxy.
It's recommended to do this early as early in boot as possible, see the
[Toxiproxy README](https://github.com/shopify/toxiproxy#Usage). If you have many
proxies, we recommend storing the Toxiproxy configs in a configuration file.
