#
# Copyright 2015 Chef Software, Inc
#
#
# NOTE: Name the file to match the ruby version you want to install.
#       as ruby-x.y.z[-pX]

parts = File.basename(__FILE__).split("-", 3)
if parts.length != 2
  raise "The ruby project file must be named in the form ruby-A-B.C[-Z]"
end
ruby_version = parts.last

ruby_version = '2.1.4'
maintainer 'Chef Software, Inc'
homepage 'https://chef.io'
build_version ruby_version
name "omnibus-ruby-#{ruby_version}"
install_dir "/opt/chef-software/#{name}"
build_iteration 1
override :ruby, version: ruby_version

dependency "preparation"
dependency "ruby"
dependency "bundler"
dependency "version-manifest"

exclude "**/.git"
exclude "**/bundler/git"

