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
      status, _time, out, _err = run(name, '--version')
      return nil unless status.zero?
      version_line = out.lines.first.chomp
      raise "bad version line #{version_line}" unless
        version_line =~ /([0-9.]+)$/
      Regexp.last_match(1)
    end

    def command(target, level)
      [name, '--keep', "-#{level}", target]
    end
  end
end
