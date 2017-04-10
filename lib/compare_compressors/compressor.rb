# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

module CompareCompressors
  #
  # Base class for compressors.
  #
  class Compressor
    def evaluate(target)
      levels.map { |level| evaluate_level(target, level) }
    end

    def evaluate_level(target_pathname, level)
      Dir.mktmpdir do |tmp|
        target = File.join(tmp, 'target')
        FileUtils.cp target_pathname, target

        status, compression_time, compression_max_rss, out, err = \
          run(tmp, *compression_command(target, level))
        raise "compress: #{name} failed:\n#{out}\n#{err}" unless status.zero?

        size = output_size(target)
        remove_if_exists(target)

        status, decompression_time, decompression_max_rss, out, err = \
          run(tmp, *decompression_command(target))
        raise "decompress: #{name} failed:\n#{out}\n#{err}" unless status.zero?

        Result.new(
          target_pathname, name, level, compression_time, compression_max_rss,
          size, decompression_time, decompression_max_rss
        )
      end
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

    private

    def run(tmp, *command, **options)
      out_pathname = File.join(tmp, 'out')
      err_pathname = File.join(tmp, 'err')
      options[:out] = out_pathname
      options[:err] = err_pathname
      options[:in] = '/dev/null'

      # Note: this is not the shell builtin but rather /usr/bin/time; at least
      # on Ubuntu, the latter reports both time and max RSS (memory usage)
      # metrics, which is what we want here. Write the time output to a
      # temporary file to avoid conflicting with the child's stderr output.
      time_pathname = File.join(tmp, 'time')
      timed_command = [
        'time', '--format=%S %U %M', "--output=#{time_pathname}"
      ] + command

      Process.waitpid(Process.spawn(*timed_command, **options))

      [
        $CHILD_STATUS.exitstatus,
        *parse_time(time_pathname),
        File.read(out_pathname),
        File.read(err_pathname)
      ]
    end

    # Returns total (system plus user) CPU time in seconds, and maximum resident
    # set size (memory usage) in Kilobytes, which I think means KiB.
    def parse_time(time_pathname)
      sys, user, max_rss = File.read(time_pathname).split
      [sys.to_f + user.to_f, max_rss.to_i]
    end

    def remove_if_exists(pathname)
      FileUtils.rm pathname
    rescue Errno::ENOENT
      nil # not a problem
    end
  end
end
