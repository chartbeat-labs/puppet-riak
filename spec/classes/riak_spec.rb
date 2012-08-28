# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'spec_helper'
require 'shared_contexts'

describe 'riak', :type => :class do

  let(:title) { "riak" }
  let(:facts) {{ :ipaddress => '10.42.0.5'}}

  include_context 'hieradata'

  describe 'at baseline with defaults' do
    let(:params) {{}}
    it { should contain_class('riak') }
    it { should contain_httpfile('/tmp/riak-1.2.0.deb').with_ensure('present') }
    it { should contain_package('riak').with_ensure('latest') }
    it { should contain_service('riak').with({
        :ensure => 'running',
        :enable => 'true'
      }) }
    it { should contain_file('/etc/riak/app.config').with({ :owner => 'root',
        :group => 'root', :mode => '0644', :ensure => 'present' }) }
    it { should contain_file('/etc/riak/vm.args').with({ :owner => 'root',
        :group => 'root', :mode => '0644', :ensure => 'present' }) }
  end

  describe 'custom package configuration' do
    let(:params) { { :version => '1.2.0', :package => 'custom_riak', 
                     :package_hash => 'abcd' } }
    it 'should be downloading latest' do
      subject.should contain_httpfile('/tmp/custom_riak-1.2.0.deb').
        with({
          :path => '/tmp/custom_riak-1.2.0.deb',
          :hash => 'abcd' })
    end
    it { should contain_package('riak').
        with({ 
          :ensure => 'latest', 
          :source =>'/tmp/custom_riak-1.2.0.deb'}) }
  end

  def res t, n
    catalogue.resource(t, n).send(:parameters)
  end

  describe 'when changing configuration' do
    #before(:all) { puts catalogue.resources }
    it("will restart Service") { 
      res('file', '/etc/riak/app.config')[:notify].
        should eq('Service[riak]') }
  end

  describe 'when changing configuration, the service' do
    let(:params) { { :service_autorestart => false } }
    it('will not restart') { 
      res('file', '/etc/riak/app.config')[:notify].nil?.should be_true }
  end
end
