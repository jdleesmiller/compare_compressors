# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

module CompareCompressors
  #
  # Group and summarise results.
  #
  class Grouper
    # Default to current Amazon S3 storage cost per GiB*month ($).
    DEFAULT_GIBYTE_COST = 0.023

    # Default to on-demand cost for an Amazon EC2 m3.medium ($).
    DEFAULT_HOUR_COST = 0.073

    # Default to single decompression per compression
    DEFAULT_DECOMPRESSION_COUNT = 1

    def initialize(gibyte_cost:, hour_cost:, decompression_count:, scale:)
      @gibyte_cost = gibyte_cost.to_f
      @hour_cost = hour_cost.to_f
      @decompression_count = decompression_count.to_f
      @scale = scale.to_f
    end

    attr_reader :gibyte_cost
    attr_reader :hour_cost
    attr_reader :decompression_count
    attr_reader :scale

    def group(results)
      results.group_by(&:group_key).map do |_, group_results|
        targets = group_results.map(&:target)
        uncompressed_sizes = targets.map { |target| File.stat(target).size }
        compression_ratios = group_results.zip(uncompressed_sizes).map do |r, u|
          u / r.size.to_f
        end
        compression_deltas = group_results.zip(uncompressed_sizes).map do |r, u|
          u - r.size
        end

        n = group_results.size.to_f
        mean_compression_cpu_hours =
          scale *
          group_results.map(&:compression_cpu_time).inject(&:+) / n / 3600.0
        max_compression_max_rss =
          group_results.map(&:compression_max_rss).max
        mean_compressed_gibytes =
          scale * group_results.map(&:size).inject(&:+) / n / 1024**3
        mean_decompression_cpu_hours =
          scale * decompression_count *
          group_results.map(&:decompression_cpu_time).inject(&:+) / n / 3600.0
        max_decompression_max_rss =
          group_results.map(&:decompression_max_rss).max
        total_cpu_hours =
          mean_compression_cpu_hours + mean_decompression_cpu_hours
        GroupResult.new(
          group_results.first.compressor_name,
          group_results.first.compressor_level,
          mean_compression_cpu_hours,
          max_compression_max_rss,
          mean_compressed_gibytes,
          scale * compression_deltas.inject(&:+) / n / 1024**3,
          compression_ratios.inject(&:*)**(1 / n),
          mean_decompression_cpu_hours,
          max_decompression_max_rss,
          total_cpu_hours,
          mean_compressed_gibytes * gibyte_cost,
          mean_compression_cpu_hours * hour_cost,
          mean_decompression_cpu_hours * hour_cost
        )
      end
    end

    def summarize(grouped_results, top = 5)
      grouped_results.sort_by(&:total_cost).take(top)
    end

    def find_non_dominated(group_results)
      group_results.reject do |group_result0|
        group_results.any? do |group_result1|
          group_result1.dominates?(group_result0)
        end
      end
    end
  end
end
