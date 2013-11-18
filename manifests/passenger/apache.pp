class rvm::passenger::apache(
  $ruby_version,
  $version,
  $rvm_prefix = '/usr/local',
  $mininstances = '1',
  $maxpoolsize = '6',
  $poolidletime = '300',
  $maxinstancesperapp = '0',
  $spawnmethod = 'smart-lv2'
) {

  class { 'rvm::passenger::gem':
    ruby_version => $ruby_version,
    version      => $version,
  }

  # TODO: How can we get the gempath automatically using the ruby version
  # Can we read the output of a command into a variable?
  # e.g. $gempath = `usr/local/rvm/bin/rvm ${ruby_version} exec rvm gemdir`
  $gempath = "${rvm_prefix}/rvm/gems/${ruby_version}/gems"
  $binpath = "${rvm_prefix}/rvm/bin/"
  $gemroot = "${gempath}/passenger-${version}"

  # build the Apache module
  # different passenger versions put the built module in different places (ext, libout, buildout)
  #  include apache::dev
  exec { 'passenger-install-apache2-module':
    command     => "${rvm::passenger::apache::binpath}rvm ${rvm::passenger::apache::ruby_version} exec passenger-install-apache2-module -a",
    unless      => "test -f ${gemroot}/ext/apache2/mod_passenger.so || test -f ${gemroot}/libout/apache2/mod_passenger.so || test -f ${gemroot}/buildout/apache2/mod_passenger.so",
    environment => [ 'HOME=/root', ],
    path        => '/usr/bin:/usr/sbin:/bin',
    require     => Class['rvm::passenger::gem'],
  }

  class { 'rvm::mod::passenger':
    passenger_root           => $gemroot,
    passenger_ruby           => "${rvm_prefix}/rvm/wrappers/${ruby_version}/ruby",
    passenger_max_pool_size  => $maxpoolsize,
    passenger_pool_idle_time => $poolidletime,
    require                  => Exec['passenger-install-apache2-module'],
    subscribe                => Exec['passenger-install-apache2-module'],
  }
}

class rvm::mod::passenger (
  $passenger_high_performance = undef,
  $passenger_pool_idle_time = undef,
  $passenger_max_requests = undef,
  $passenger_stat_throttle_rate = undef,
  $rack_autodetect = undef,
  $rails_autodetect = undef,
  $passenger_root = undef,
  $passenger_ruby = undef,
  $passenger_max_pool_size = undef,
  $passenger_use_global_queue = undef,
) {
# Template uses:
# - $passenger_root
# - $passenger_ruby
# - $passenger_max_pool_size
# - $passenger_high_performance
# - $passenger_max_requests
# - $passenger_stat_throttle_rate
# - $passenger_use_global_queue
# - $rack_autodetect
# - $rails_autodetect
  file { 'passenger.conf':
    ensure => file,
    path => "/etc/httpd/conf.d/passenger.conf",
    content => template('rvm/passenger.conf.erb'),
    require => Package['httpd'],
    notify => Service['httpd'],
  }
}
