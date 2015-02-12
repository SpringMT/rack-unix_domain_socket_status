require 'json'

module Rack
  class UnixDomainSocketStatus
    def initialize(app, options={})
      @app = app
      raw_unix_domain_socket_path = options.delete(:unix_domain_socket_path) || raise('unix_domain_socket_path is required')
      raw_unix_domain_socket_path.force_encoding(Encoding::BINARY) if defined?(Encoding)
      @unix_domain_socket_path = Regexp.escape raw_unix_domain_socket_path
      @options = {
        path:  '/unix_status',
        status: 200,
        headers: {'Content-Type' => 'application/json'},
        proc_net_unix_args: %w(/proc/net/unix)
      }.merge(options)
    end

    def call(env)
      if env['PATH_INFO'] == @options[:path]
        status = @options[:status]
        body = [calculate_unix_domain_socket_status]
        headers = @options[:headers]
        [status, headers, body]
      else
        @app.call(env)
      end
    end

    private
    # DO NOT ALLOW nil unix_domain_socket_path
    # https://github.com/torvalds/linux/blob/master/include/uapi/linux/net.h#L47
    #
    def calculate_unix_domain_socket_status
      # label in /proc/net/unix
      #         Num: RefCount Protocol Flags Type St Inode Path
      paths = /^\w+: \d+ 00000000 \d+ \d+ (\d+) \d+ #{@unix_domain_socket_path}$/n

      queued = 0
      active = 0
      # no point in pread since we can't stat for size on this file
      ::File.read(*@options[:proc_net_unix_args].push({encoding: 'binary'})).scan(paths) do |s|
        case s[0].to_i
        when 2 then queued += 1 # SS_CONNECTING
        when 3 then active += 1 # SS_CONNECTED
        end
      end
      {active: active, queued: queued, total: active + queued}.to_json
    end

  end
end

