`__END__` storage
=================

Stored shit in your script's data segment.


Install
-------

```sh
$ gem install __END__storage
```


Example
-------

A program that records how many times it's been run:

```ruby
require '__END__storage'

storage   = END__storage.new DATA
run_count = storage.load.to_i + 1
storage.save run_count

puts "Run count: #{run_count}"

__END__
0
```

When we invoke it, it increments the counter,
which it stores in its `DATA` segment.

```sh
$ ruby count_runs.rb
1

$ ruby count_runs.rb
2

$ ruby count_runs.rb
3

$ cat count_runs.rb
require '__END__storage'

storage   = __END__storage DATA
run_count = storage.load.to_i + 1
storage.save run_count

puts "Run count: #{run_count}"

__END__
3
```


License
-------

Just do what the fuck you want to.

[http://www.wtfpl.net/about/](http://www.wtfpl.net/about/)
