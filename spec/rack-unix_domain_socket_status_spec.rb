require 'json'
require File.dirname(__FILE__) + '/spec_helper'

describe Rack::UnixDomainSocketStatus do
  app = lambda { |env|
    [200, {'Content-Type' => 'text/plain'}, ["Hello, World!"]]
  }

  context 'confirm to Rack::Lint' do
    subject do
      Rack::Lint.new( Rack::UnixDomainSocketStatus.new(app, {unix_domain_socket_path: 'test.sock', proc_net_unix_path: 'tmp/dummy_unix'}) )
    end
    it do
      response = Rack::MockRequest.new(subject).get('/')
      expect(response.body).to eq 'Hello, World!'
    end
    it do
      response = Rack::MockRequest.new(subject).get('/unix_status')
      expect(response.body).to eq({active: 0, queued: 0, total: 0}.to_json)
    end
  end

  context 'change path' do
    subject do
      Rack::Lint.new( Rack::UnixDomainSocketStatus.new(app, {unix_domain_socket_path: 'test.sock', proc_net_unix_path: 'tmp/dummy_unix', path: '/us'}) )
    end
    it do
      response = Rack::MockRequest.new(subject).get('/us')
      expect(response.body).to eq({active: 0, queued: 0, total: 0}.to_json)
    end
  end

  context 'NOT exist proc_net_unix' do
    subject do
      Rack::Lint.new( Rack::UnixDomainSocketStatus.new(app, {unix_domain_socket_path: 'test.sock', proc_net_unix_path: 'tmp/hoge'}) )
    end
    it do
      response = Rack::MockRequest.new(subject).get('/unix_status')
      expect(response.body).to eq 'Hello, World!'
    end
  end

end

