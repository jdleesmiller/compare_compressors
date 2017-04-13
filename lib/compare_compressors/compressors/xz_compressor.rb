# frozen_string_literal: true

module CompareCompressors
  #
  # Compress with `xz` (LZMA).
  #
  class XzCompressor < Compressor
    def name
      'xz'
    end

    def extension
      'xz'
    end

    def levels
      (0..9).to_a
    end

    def version
      status, _times, out, _err = run(name, '--version')
      return nil unless status.zero?
      version_line = out.lines.first.chomp
      raise "bad version line #{version_line}" unless
        version_line =~ /([0-9.a-z]+)$/
      Regexp.last_match(1)
    end

    def compression_command(target, level)
      ['xz', "-#{level}", target]
    end

    def decompression_command(target)
      ['unxz', output_name(target)]
    end
  end
end
