# frozen_string_literal: true

module CompareCompressors
  #
  # Compress with Brotli.
  #
  class BrotliCompressor < Compressor
    def name
      'brotli'
    end

    def extension
      'bro'
    end

    # Can't find any documentation about this, so this is based on
    # https://github.com/google/brotli/blob/cdca91b6f59dd7632985667d2cd585ab68937b48/enc/quality.h
    def levels
      (0..11).to_a
    end

    # The `bro` command does not seem to have anything that prints a version.
    def version
      '?'
    end

    def command(target, level)
      [
        'bro',
        '--input', target,
        '--output', output_name(target),
        '--quality', level.to_s
      ]
    end
  end
end
