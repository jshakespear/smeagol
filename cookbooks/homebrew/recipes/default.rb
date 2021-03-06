#
# Cookbook Name:: homebrew
# Recipe:: homebrew
#

root = File.expand_path(File.join(File.dirname(__FILE__), ".."))

require root + '/resources/homebrew'
require root + '/providers/homebrew'
require 'etc'

directory "#{ENV['HOME']}/Developer" do
  action :create
end

execute "download homebrew installer" do
  command "/usr/bin/curl -sfL http://github.com/mxcl/homebrew/tarball/master | /usr/bin/tar xz -m --strip 1"
  cwd     "#{ENV['HOME']}/Developer"
  not_if  "test -e ~/Developer/bin/brew"
end

template "#{ENV['HOME']}/.cider.profile" do
  mode   0700
  owner  ENV['USER']
  group  Etc.getgrgid(Process.gid).name
  source "dot.profile.erb"
  variables({ :home => ENV['HOME'] })
end

%w(bash_profile bashrc zshrc).each do |config_file|
  execute "include cider environment into defaults for ~/.#{config_file}" do
    command "if [ -f ~/.#{config_file} ]; then echo 'source ~/.cider.profile' >> ~/.#{config_file}; fi"
    not_if  "grep -q 'cider.profile' ~/.#{config_file}"
  end
end

execute "setup cider profile sourcing in ~/.profile" do
  command "echo 'source ~/.cider.profile' >> ~/.profile"
  not_if  "grep -q 'cider.profile' ~/.profile"
end

homebrew "git"
script "updating homebrew from github" do
  interpreter "bash"
  code <<-EOS
    source ~/.cider.profile
    PATH=#{ENV['HOME']}/Developer/bin:$PATH; export PATH
    ~/Developer/bin/brew update >> ~/.cider.log 2>&1
  EOS
end
