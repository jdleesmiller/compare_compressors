# frozen_string_literal: true

module CompareCompressors
  #
  # Compress with gzip. Many compression tools provide a gzip-compatible
  # interface, so this is also used as a base class for several other
  # compressors.
  #
  class GzipCompressor < Compressor
    def name
      'gzip'
    end

    def extension
      'gz'
    end

    def levels
      (1..9).to_a
    end

    def version
      status, _time, _out, err = run(name, '--help')
      return nil unless status.zero?
      err.lines.first.chomp
    end

    def command(target, level)
      [name, '--keep', "-#{level}", target]
    end
  end
end
