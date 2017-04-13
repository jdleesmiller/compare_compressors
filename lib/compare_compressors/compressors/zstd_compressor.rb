# frozen_string_literal: true

module CompareCompressors
  #
  # Compress with Zstandard.
  #
  class ZstdCompressor < Compressor
    def name
      'zstd'
    end

    def extension
      'zst'
    end

    def levels
      (1..19).to_a
    end

    def version
      status, _times, out, _err = run(name, '-V')
      return nil unless status.zero?
      version_line = out.lines.first.chomp
      raise "bad version line #{version_line}" unless
        version_line =~ /([0-9.]+),/
      Regexp.last_match(1)
    end

    def compression_command(target, level)
      ['zstd', "-#{level}", target]
    end

    def decompression_command(target)
      ['unzstd', output_name(target)]
    end
  end
end
