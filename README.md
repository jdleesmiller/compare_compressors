# compare_compressors

* TODO url

## Synopsis

TODO description

### Usage

```ruby
TODO (code sample of usage)
```

With docker:
```
docker run --rm --volume \
  /Users/john/compare_compressors/data:/home/app/compare_compressors/data \
  compare_compressors compare data/test* >data/compare.csv
docker run --rm --volume \
  /Users/john/compare_compressors/data:/home/app/compare_compressors/data \
  compare_compressors plot data/compare.csv | gnuplot
```

## Requirements

* TODO (list of requirements)

## Installation

```
gem install compare_compressors
```

## Development

To run the tests inside the docker container:

```
docker run --rm -it --entrypoint='' \
  --volume=compare_compressors_bundle:/home/app/compare_compressors/.bundle \
  --volume=`pwd`:/home/app/compare_compressors \
  compare_compressors bundle exec rake
```

TODO developer advice

## Related

See also https://quixdb.github.io/squash-benchmark/

## License

(The MIT License)

Copyright (c) 2017 TODO

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
