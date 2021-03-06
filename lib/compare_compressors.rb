# frozen_string_literal: true

require 'English'

require_relative 'compare_compressors/version'

require_relative 'compare_compressors/comparer'
require_relative 'compare_compressors/cost_model'
require_relative 'compare_compressors/result'
require_relative 'compare_compressors/group_result'
require_relative 'compare_compressors/costed_group_result'

require_relative 'compare_compressors/plotter'
require_relative 'compare_compressors/plotters/cost_plotter'
require_relative 'compare_compressors/plotters/raw_plotter'
require_relative 'compare_compressors/plotters/size_plotter'

require_relative 'compare_compressors/compressor'
require_relative 'compare_compressors/compressors/brotli_compressor'
require_relative 'compare_compressors/compressors/bzip2_compressor'
require_relative 'compare_compressors/compressors/gzip_compressor'
require_relative 'compare_compressors/compressors/seven_zip_compressor'
require_relative 'compare_compressors/compressors/xz_compressor'
require_relative 'compare_compressors/compressors/zstd_compressor'

require_relative 'compare_compressors/command_line_interface'

#
# Compare compression algorithms.
#
module CompareCompressors
  COMPRESSORS = [
    BrotliCompressor,
    Bzip2Compressor,
    GzipCompressor,
    SevenZipCompressor,
    XzCompressor,
    ZstdCompressor
  ].map(&:new).freeze
end
