# frozen_string_literal: true

module CompareCompressors
  #
  # Compress with bzip2.
  #
  class Bzip2Compressor < GzipCompressor
    def name
      'bzip2'
    end

    def extension
      'bz2'
    end

    def version
      version_line = super
      raise "bad #{name} version line: #{version_line.inspect}" unless
        version_line =~ /Version (.+)\.\z/
      Regexp.last_match(1)
    end

    def compression_command(target, level)
      ['bzip2', "-#{level}", target]
    end

    def decompression_command(target)
      ['bunzip2', output_name(target)]
    end
  end
end
