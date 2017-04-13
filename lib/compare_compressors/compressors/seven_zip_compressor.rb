# frozen_string_literal: true

module CompareCompressors
  #
  # Compress with `7z`.
  #
  class SevenZipCompressor < Compressor
    def name
      'seven_zip'
    end

    def display_name
      '7z'
    end

    def extension
      '7z'
    end

    # Based on share/doc/p7zip/DOC/MANUAL/cmdline/switches/method.htm
    # Level 0 is no compression, so we exclude it.
    def levels
      [1, 3, 5, 7, 9]
    end

    def version
      status, _times, out, _err = run('7zr', '--help')
      return nil unless status.zero?
      version_line = out.strip.lines.first.chomp
      raise "bad version line #{version_line}" unless
        version_line =~ /([0-9.]+)[\s:]+Copyright/
      Regexp.last_match(1)
    end

    def compression_command(target, level)
      ['7zr', 'a', "-mx=#{level}", output_name(target), target]
    end

    def decompression_command(target)
      ['7zr', 'x', "-o#{File.dirname(target)}", output_name(target)]
    end
  end
end
