require File.dirname(__FILE__) + '/spec_helper'

use Rack::UnixDomainSocketStatus, unix_domain_socket_path: ''

app = lambda {|env|
    [200, {'Content-Type' => 'text/plain'}, [ 'Hello World' ]]
}

run app
