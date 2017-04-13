# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

module CompareCompressors
  #
  # Base class for compressors.
  #
  class Compressor
    def evaluate(tmp, target, target_pathname, level)
      compression_times = run_action(
        'compress', tmp, compression_command(target_pathname, level)
      )

      size = output_size(target_pathname)
      remove_if_exists(target_pathname)

      decompression_times = run_action(
        'decompress', tmp, decompression_command(target_pathname)
      )

      remove_if_exists(output_name(target_pathname))

      Result.new(
        target, name, level, *compression_times, size, *decompression_times
      )
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

    def run_action(action, tmp, command)
      status, times, out, err = run(tmp, command)
      raise "#{action}: #{name} failed:\n#{out}\n#{err}" unless status.zero?
      times
    end

    def run(tmp, command, **options)
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
        'time', '--format=%e %S %U %M', "--output=#{time_pathname}"
      ] + command

      Process.waitpid(Process.spawn(*timed_command, **options))

      [
        $CHILD_STATUS.exitstatus,
        parse_time(time_pathname),
        File.read(out_pathname),
        File.read(err_pathname)
      ]
    end

    def run_version_command(*command)
      Dir.mktmpdir do |tmp|
        status, _times, out, err = run(tmp, command)
        [status, out, err]
      end
    end

    # Returns elapsed time in seconds, total (system plus user) CPU time in
    # seconds, and maximum resident set size (memory usage) in Kilobytes, which
    # I think means KiB.
    def parse_time(time_pathname)
      elapsed, sys, user, max_rss = File.read(time_pathname).split
      [elapsed.to_f, sys.to_f + user.to_f, max_rss.to_i]
    end

    def remove_if_exists(pathname)
      FileUtils.rm pathname
    rescue Errno::ENOENT
      nil # not a problem
    end
  end
end
