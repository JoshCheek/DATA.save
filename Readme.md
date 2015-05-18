`DATA.save`
===========

Stored shit in your script's data segment.


Install
-------

```sh
$ gem install DATA.save
```


Example
-------

A program that records how many times it's been run:

```ruby
require 'DATA.save'

run_count = DATA.load.to_i
run_count += 1
DATA.save run_count

puts "Run count: #{run_count}"

__END__
0
```

When we invoke it, it increments the counter,
which it stores in its `DATA` segment.

```sh
# run it 3 times
$ ruby count_runs.rb
Run count: 1

$ ruby count_runs.rb
Run count: 2

$ ruby count_runs.rb
Run count: 3

# now check out the file
$ cat count_runs.rb
require 'DATA.save'

run_count = DATA.load.to_i
run_count += 1
DATA.save run_count

puts "Run count: #{run_count}"

__END__
3
```


License
-------

Just do what the fuck you want to.

[http://www.wtfpl.net/about/](http://www.wtfpl.net/about/)
