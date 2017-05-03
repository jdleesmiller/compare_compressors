# compare_compressors

https://github.com/jdleesmiller/compare_compressors

[![Build Status](https://travis-ci.org/jdleesmiller/compare_compressors.svg?branch=master)](https://travis-ci.org/jdleesmiller/compare_compressors)

## Synopsis

Evaluate different compression tools and their settings by running them on a sample of data.

See [this blog post for an example of how to use the tool](http://jdlm.info/articles/2017/05/01/compression-pareto-docker-gnuplot.html).

### Usage

This utility has many system dependencies, so the easiest way to run it is via Docker:

```shell
$ docker pull jdleesmiller/compare_compressors
```

Generally you will run a `compare` step, followed by a `plot` or `summarize` step.

#### Compare

This step runs the compressors on the sample files and saves the results to a CSV. Assuming that your sample files are in a folder called `data` in the current directory, and they are called `test1`, `test2`, etc.., the command would look like:

```
docker run --rm \
  --volume `pwd`/data:/home/app/compare_compressors/data:ro \
  --volume /tmp:/tmp \ # optional
  jdleesmiller/compare_compressors compare data/test* >data/compare.csv
```

where:

- The `--rm` flag tells docker to remove the container when it's finished.

- The ```--volume `pwd`/data:/home/app/compare_compressors/data:ro``` flag mounts `./data` on the host inside the container, so the utility can access the sample files. The trick here is that `/home/app/compare_compressors` is the utility's working directory inside the container, so the relative paths `data/test*` for the sample files will be the same both inside and outside of the container. The `:ro` makes it a read only mount; this is optional, but it provides added assurance that the utility won't change your data files.

- The `--volume /tmp:/tmp` flag is optional but may improve performance. The utility does its compression and decompression in `/tmp` inside the container, and all of the writes inside the container go through Docker's union file system. By mounting `/tmp` on the host, we bypass the union file system. (Ideally, we'd just do this in the Dockerfile, but unfortunately it's 10x slower on Docker for Mac; hopefully that will improve soon.)

#### Plot

Once you've generated a CSV with results, the tool can read the CSV and generate a `gnuplot` script to plot the results. Note that you need to have `gnuplot` installed on the host for this to work.

There are several plotting commands: `plot` gives you a 2D plot of compression time vs compressed size. There is also a `--decompression` option to plot decompression time vs compressed size instead.

```
docker run --rm \
  --volume `pwd`/data:/home/app/compare_compressors/data:ro \
  --volume /tmp:/tmp \
  jdleesmiller/compare_compressors plot data/compare.csv | gnuplot
```

The `plot_costs` command takes three cost coefficients: cost per GiB of stored data, cost per hour to run the compression program, and cost per hour to run the decompression program. The program then computes a simple linear cost function. To keep the plot in 2D, the two time costs are added together.

```
docker run --rm \
  --volume `pwd`/data:/home/app/compare_compressors/data:ro \
  --gibyte-cost 56.05 \
  --compression-hour-cost 32.35 \
  --decompression-hour-cost 177.91 \
  --currency '£' \
  jdleesmiller/compare_compressors plot_costs data/compare.csv | gnuplot
```

#### Summarize

Print a list of the compressors and settings in descending order by cost. The cost function is of the same form as for `plot_costs`.

```
docker run --rm \
  --volume `pwd`/data:/home/app/compare_compressors/data \
  --gibyte-cost 56.05 \
  --compression-hour-cost 32.35 \
  --decompression-hour-cost 177.91 \
  --currency '£' \
  jdleesmiller/compare_compressors summarize data/compare.csv
```

## Requirements

A linux-like `/usr/bin/time` utility is required, along with several system packages. See the [Dockerfile](Dockerfile) for a list of the packages that this utility depends on. To make the plot, you will also need `gnuplot`.

If you are installing natively, without docker, you will need ruby and then to install the gem:

```
$ gem install compare_compressors
```

## Development

For development, you will probably want (1) override the default entrypoint and (2) mount the application root inside the container. To run the tests, for example:

```
docker run --rm -it --entrypoint='' \
  --volume=compare_compressors_bundle:/home/app/compare_compressors/.bundle \
  --volume=`pwd`:/home/app/compare_compressors \
  compare_compressors bundle exec rake
```

The only caveat is that you need to preserve the `.bundle` folder inside the container by mounting it as a volume; the above command does this using a named volume, `compare_compressors_bundle`, which will persist between runs and be easier to identify in the `docker volume ls` output.

## Related

- See [this blog post for an example of how to use the tool](http://jdlm.info/articles/2017/05/01/compression-pareto-docker-gnuplot.html).
- For many more compression algorithms, see https://quixdb.github.io/squash-benchmark/

## License

(The MIT License)

Copyright (c) 2017 John Lees-Miller

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
