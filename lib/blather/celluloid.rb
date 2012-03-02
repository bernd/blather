require 'celluloid/io'
require 'openssl'

module Blather
  class Celluloid
    include ::Celluloid::IO

    def initialize(host, port, stream, client, jid, pass, connect_timeout)
      @socket = ::Celluloid::IO::TCPSocket.new(host, port)
      @stream = stream.new(self, client, jid, pass, connect_timeout)

# later
#      run!
    end

    def start_ssl(ssl_context)
      peer_cert = nil

      @socket.wrap_socket do |socket|
        OpenSSL::SSL::SSLSocket.new(socket, ssl_context).tap do |s|
          s.sync_close = true
          s.connect
          peer_cert = s.peer_cert
        end
      end

      peer_cert
    end

    def run
      @socket.wait_writable

      @stream.connection_completed
      @stream.post_init

      loop { handle_data!(@socket.readpartial(4096)) }
# Might be used later.
#    rescue IOError
    end

    def handle_data(chunk)
      @stream.receive_data(chunk)
    end

    def write(data)
      @socket.write(data)
    end

    def close
      @stream.unbind
      @socket.close
    end
  end
end
