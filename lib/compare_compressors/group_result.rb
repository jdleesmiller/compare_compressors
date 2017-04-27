# frozen_string_literal: true

module CompareCompressors
  #
  # A single compressor-level result averaged the over targets.
  #
  GroupResult = Struct.new(
    :compressor_name,
    :compressor_level,
    :mean_compression_elapsed_hours,
    :mean_compression_cpu_hours,
    :max_compression_max_rss,
    :mean_compressed_gibytes,
    :mean_compression_delta_gibytes,
    :geomean_compression_ratio,
    :mean_decompression_elapsed_hours,
    :mean_decompression_cpu_hours,
    :max_decompression_max_rss
  ) do
    DEFAULT_SCALE = 1.0

    HOUR = 3600 # seconds
    GIGABYTE = 1024**3 # bytes

    #
    # Create a GroupResult for a group of Results for the same compressor
    # and level (but possibly multiple targets).
    #
    def self.new_from_results(compressor_name, compressor_level, results, scale)
      new(
        compressor_name,
        compressor_level,
        scale * Result.mean(results, :compression_elapsed_time) / HOUR,
        scale * Result.mean(results, :compression_cpu_time) / HOUR,
        results.map(&:compression_max_rss).max,
        scale * Result.mean(results, :size) / GIGABYTE,
        scale * Result.mean(results, :compression_delta) / GIGABYTE,
        Result.geomean(results, :compression_ratio),
        scale * Result.mean(results, :decompression_elapsed_time) / HOUR,
        scale * Result.mean(results, :decompression_cpu_time) / HOUR,
        results.map(&:decompression_max_rss).max
      )
    end

    #
    # Group individual result to average across targets in the sample.
    #
    # @param [Array.<Result>] results
    # @return [Array.<GroupResult>]
    #
    def self.group(results, scale: DEFAULT_SCALE)
      results.group_by(&:group_key).map do |_, group_results|
        GroupResult.new_from_results(
          group_results.first.compressor_name,
          group_results.first.compressor_level,
          group_results,
          scale
        )
      end
    end
  end
end
