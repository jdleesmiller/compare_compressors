# frozen_string_literal: true

require 'benchmark'
require 'fileutils'
require 'tmpdir'

module CompareCompressors
  #
  # Base class for compressors.
  #
  class Compressor
    def compress(target)
      remove_output target
      levels.map { |level| compress_level(target, level) }
    end

    def compress_level(target, level)
      status, time, out, err = run(*command(target, level))
      raise "compress: #{name} failed:\n#{out}\n#{err}" unless status.zero?
      size = output_size(target)
      remove_output target
      Result.new(target, name, level, time.total, size)
    end

    def display_name
      name
    end

    def output_size(target)
      File.stat(output_name(target)).size
    end

    def output_name(target)
      "#{target}.#{extension}"
    end

    def remove_output(target)
      FileUtils.rm output_name(target)
    rescue Errno::ENOENT
      nil # not a problem
    end

    def run(*command, **options)
      Dir.mktmpdir do |tmp|
        out_pathname = File.join(tmp, 'out')
        err_pathname = File.join(tmp, 'err')
        options[:out] = out_pathname
        options[:err] = err_pathname
        time = Benchmark.measure do
          Process.waitpid(Process.spawn(*command, **options))
        end
        return [
          $CHILD_STATUS.exitstatus,
          time,
          File.read(out_pathname),
          File.read(err_pathname)
        ]
      end
    end
  end
end
