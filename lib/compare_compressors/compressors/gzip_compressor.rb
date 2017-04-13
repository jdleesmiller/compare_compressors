# frozen_string_literal: true

module CompareCompressors
  #
  # Compress with gzip.
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
      status, _times, out, _err = run(name, '--version')
      return nil unless status.zero?
      out.lines.first.chomp
    end

    def compression_command(target, level)
      ['gzip', "-#{level}", target]
    end

    def decompression_command(target)
      ['gunzip', output_name(target)]
    end
  end
end
