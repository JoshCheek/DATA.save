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

run_count = __END__storage.load.to_i
run_count += 1
__END__storage.save run_count

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
require '__END__storage'

run_count = __END__storage.load.to_i
run_count += 1
__END__storage.save run_count

puts "Run count: #{run_count}"

__END__
3
```

Your data segment not in `DATA`?
No biggie, you can the data segment in:

```ruby
require_relative 'lib/__END__storage'
require 'tempfile'

Tempfile.open 'tmp' do |file|
  file.write "body-olddata"
  file.seek 5
  storage = __END__storage file
  storage.save "newdata"
  puts "FILE: #{File.read file}"
end

# >> FILE: body-newdata
```


License
-------

Just do what the fuck you want to.

[http://www.wtfpl.net/about/](http://www.wtfpl.net/about/)
