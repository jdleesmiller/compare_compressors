# frozen_string_literal: true

require 'benchmark'
require 'fileutils'
require 'tmpdir'

module CompareCompressors
  #
  # A single compressor-level result.
  #
  Result = Struct.new(
    :target,
    :compressor_name,
    :compressor_level,
    :compression_elapsed_time,
    :compression_cpu_time,
    :compression_max_rss,
    :size,
    :decompression_elapsed_time,
    :decompression_cpu_time,
    :decompression_max_rss
  ) do
    def group_key
      [compressor_name, compressor_level]
    end

    #
    # @return [Integer] in bytes; cached
    #
    def uncompressed_size
      @uncompressed_size ||= File.stat(target).size
    end

    #
    # @return [Float] positive; should be finite; larger is better
    #
    def compression_ratio
      uncompressed_size / size.to_f
    end

    #
    # @return [Integer] should be positive; larger is better
    #
    def compression_delta
      uncompressed_size - size
    end

    def self.read_csv(io)
      results = []
      CSV(io, headers: true) do |csv|
        csv.each do |row|
          results << Result.from_row(row)
        end
      end
      results
    end

    def self.from_row(row)
      Result.new(
        row['target'],
        row['compressor_name'],
        row['compressor_level'].to_i,
        row['compression_elapsed_time'].to_f,
        row['compression_cpu_time'].to_f,
        row['compression_max_rss'].to_i,
        row['size'].to_i,
        row['decompression_elapsed_time'].to_f,
        row['decompression_cpu_time'].to_f,
        row['decompression_max_rss'].to_i
      )
    end

    def self.mean(results, attribute)
      results.map(&attribute).inject(&:+) / results.size.to_f
    end

    def self.geomean(results, attribute)
      results.map(&attribute).inject(&:*)**(1 / results.size.to_f)
    end
  end
end
