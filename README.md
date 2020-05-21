# Yaq

Yet Another Queue module for Elixir

## About

`Yaq` implements a double-ended queue in Elixir without using the Erlang
`:queue` module.  While very nice, `:queue` has a few limitations that I 
needed to work past:
 * Some of the commands in `:queue` return a `badarg` instead of best-effort 
   values.  For example, calling `:queue(n, q)` when `n` is larger than the 
   size of `q` raises an `ArgumentError` instead of giving me some value less
   than n.  This may be fine in many circumstances, but my use cases just ask
   for some value in return.
 * Getting the size of `:queue` is an O(N) operation, when it should be O(1)
 * I wanted a module that I could use with other common Elixir libraries, 
   such as `Enum`
 * `:queue` is not very pipeable.  The `|>` operator is very convenient and 
   one of the killer features of Elixir

`Yaq` implements the `Enum` and `Collectable` protocols
 
## Features
* Double-ended quque
* Implements Enumerable, Collectable protocols

## Installation

The package can be installed by adding `yaq` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:yaq, "~> 1.0.0"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/yaq](https://hexdocs.pm/yaq).

## License
Copyright 2020 Nicholas David McKinney

Licensed under Apache License 2.0
Check LICENSE and NOTICE files for more information

