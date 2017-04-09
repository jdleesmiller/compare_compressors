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
    :time,
    :max_rss,
    :size
  ) do
    def group_key
      [compressor_name, compressor_level]
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
        row['time'].to_f,
        row['max_rss'].to_i,
        row['size'].to_i
      )
    end
  end
end
