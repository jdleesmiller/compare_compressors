# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'

require 'compare_compressors'

class TestCompareCompressors < MiniTest::Test
  include CompareCompressors

  def test_compressors
    COMPRESSORS.each do |compressor|
      check_compressor(compressor)
    end
  end

  def test_compressor_versions
    COMPRESSORS.each do |compressor|
      assert_match(/[0-9]|\?/, compressor.version)
    end
  end

  def test_grouper_groups_over_targets
    with_fixed_test_targets(2, 10_000) do |targets|
      results = [
        Result.new(
          targets[0], 'fooz', 1, 1.1, 10.1, 1000, 5000, 3.1, 2.1, 2000
        ),
        Result.new(
          targets[0], 'fooz', 2, 2.2, 20.2, 1001, 2500, 6.2, 4.2, 2001
        ),
        Result.new(
          targets[1], 'fooz', 1, 1.3, 10.3, 1002, 4000, 3.3, 2.3, 2002
        ),
        Result.new(
          targets[1], 'fooz', 2, 2.4, 20.4, 1003, 2000, 6.4, 4.4, 2003
        )
      ]

      grouper = Grouper.new(
        gibyte_cost: 0.023,
        hour_cost: 0.05,
        decompression_count: 2,
        scale: 10_000
      )
      group_results = grouper.group(results)
      assert_equal 2, group_results.size
      assert_equal 'fooz', group_results[0].compressor_name
      assert_equal 1, group_results[0].compressor_level
      assert_in_delta \
        10_000 * (10.1 + 10.3) / 2 / 3600,
        group_results[0].mean_compression_cpu_hours
      assert_equal 1002, group_results[0].max_compression_max_rss
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
        10_000 * 2 * (2.1 + 2.3) / 2 / 3600,
        group_results[0].mean_decompression_cpu_hours
      assert_equal 2002, group_results[0].max_decompression_max_rss
      assert_in_delta \
        0.023 * group_results[0].mean_compressed_gibytes,
        group_results[0].compressed_size_cost
      assert_in_delta \
        0.05 * group_results[0].mean_compression_cpu_hours,
        group_results[0].compression_time_cost
      assert_in_delta \
        0.05 * group_results[0].mean_decompression_cpu_hours,
        group_results[0].decompression_time_cost
      assert_in_delta \
        group_results[0].total_cpu_hours,
        group_results[0].mean_compression_cpu_hours +
        group_results[0].mean_decompression_cpu_hours
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

  # An integration test for any compressor.
  def check_compressor(compressor)
    num_levels = compressor.levels.size

    with_random_test_targets(3, 100) do |targets|
      csv_string_io = StringIO.new
      CSV(csv_string_io) do |csv|
        Comparer.new.run(csv, [compressor], targets)
      end

      csv_string_io.rewind
      results = Result.read_csv(csv_string_io)
      targets.each do |target|
        target_results = results.select { |r| r.target == target }
        assert_equal num_levels, target_results.size
        assert_equal \
          target_results.map(&:compressor_level).min,
          target_results.first.compressor_level
        refute target_results.first.compression_cpu_time.negative?
        assert target_results.first.size.positive?
        refute target_results.first.decompression_cpu_time.negative?
      end

      grouper = Grouper.new(
        gibyte_cost: 0.023,
        hour_cost: 0.05,
        decompression_count: 2,
        scale: 10
      )

      # Average out the targets.
      group_results = grouper.group(results)
      assert_equal num_levels, group_results.size

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
      assert_match(/#{compressor.name} << EOD/, script)
      assert_match(/set lmargin 5/, script)
      assert_match(/set logscale y/, script)
      assert_match(/set autoscale fix/, script)
    end
  end
end
