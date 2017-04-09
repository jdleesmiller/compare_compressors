# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'

require 'compare_compressors'

class TestCompareCompressors < MiniTest::Test
  include CompareCompressors

  def test_gzip
    # Gzip is very likely to be present, so use it for integration testing.
    compressor = GzipCompressor.new
    with_random_test_targets(3, 100) do |targets|
      results = []
      targets.each do |target|
        target_results = compressor.compress(target)
        assert_equal 9, target_results.size # 9 compression levels
        assert_equal 1, target_results.first.compressor_level
        refute target_results.first.time.negative?
        assert target_results.first.size.positive?
        results.concat(target_results)
      end

      grouper = Grouper.new(gibyte_cost: 0.023, hour_cost: 0.05, scale: 10)

      # Average out the targets.
      group_results = grouper.group(results)
      assert_equal 9, group_results.size

      # There's not much we can reliably say about the pareto results, because
      # they depend on time. We can make sure it runs, however.
      pareto_results = grouper.find_non_dominated(group_results)
      assert pareto_results.size.positive?

      # Summarise the results. Again there's not much we can reliably test here.
      summary_results = grouper.summarize(group_results)
      assert_equal 5, summary_results.size

      plotter = Plotter.new(
        grouper,
        terminal: Plotter::DEFAULT_TERMINAL,
        output: Plotter::DEFAULT_OUTPUT,
        logscale_y: true,
        autoscale_fix: true,
        show_cost_contours: true,
        show_labels: true,
        lmargin: 5,
        title: 'Test Plot'
      )

      io = StringIO.new
      plotter.plot(group_results, io: io)
      script = io.string
      assert_match(/set terminal png/, script)
      assert_match(/gzip << EOD/, script)
      assert_match(/set lmargin 5/, script)
      assert_match(/set logscale y/, script)
      assert_match(/set autoscale fix/, script)
    end
  end

  def test_grouper_groups_over_targets
    with_fixed_test_targets(2, 10_000) do |targets|
      results = [
        Result.new(targets[0], 'fooz', 1, 10.1, 1000, 5000),
        Result.new(targets[0], 'fooz', 2, 20.2, 1001, 2500),
        Result.new(targets[1], 'fooz', 1, 10.3, 1002, 4000),
        Result.new(targets[1], 'fooz', 2, 20.4, 1003, 2000)
      ]

      grouper = Grouper.new(gibyte_cost: 0.023, hour_cost: 0.05, scale: 10_000)
      group_results = grouper.group(results)
      assert_equal 2, group_results.size
      assert_equal 'fooz', group_results[0].compressor_name
      assert_equal 1, group_results[0].compressor_level
      assert_in_delta \
        10_000 * (10.1 + 10.3) / 2 / 3600,
        group_results[0].mean_hours
      assert_equal 1002, group_results[0].max_rss
      assert_in_delta \
        10_000 * (5000 + 4000) / 2.0 / 1024**3,
        group_results[0].mean_compressed_gibytes
      assert_in_delta \
        10_000 * (5000 + 6000) / 2.0 / 1024**3,
        group_results[0].mean_compression_delta_gibytes
      assert_in_delta \
        Math.sqrt((10_000.0 / 5000) * (10_000.0 / 4000)),
        group_results[0].geomean_compression_ratio
      assert_in_delta \
        0.023 * group_results[0].mean_compressed_gibytes,
        group_results[0].compressed_size_cost
      assert_in_delta \
        0.05 * group_results[0].mean_hours,
        group_results[0].compression_time_cost
    end
  end

  def write_random_test_data(pathname, num_reps)
    File.open(pathname, 'w') do |f|
      num_reps.times do
        string = 'a' * rand(100) + 'b' * rand(100) + 'c' * rand(100)
        f.puts(string.split('').shuffle.join(''))
      end
    end
  end

  def with_random_test_targets(num_targets, num_reps)
    srand 42
    Dir.mktmpdir do |tmp|
      targets = Array.new(num_targets) do |i|
        pathname = File.join(tmp, "test_#{i}")
        write_random_test_data pathname, num_reps
        pathname
      end
      yield targets
    end
  end

  def with_fixed_test_targets(num_targets, target_size)
    Dir.mktmpdir do |tmp|
      targets = Array.new(num_targets) do |i|
        pathname = File.join(tmp, "test_#{i}")
        File.open(pathname, 'w') { |f| f.puts 'a' * target_size }
        pathname
      end
      yield targets
    end
  end
end
