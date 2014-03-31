# Class: moxi
#
# Moxi Server. Everything is kept in /opt/moxi as this is where the upstream
# rpm package puts everything. Arguably ugly indeed.
#
# Parameters:
#  $options:
#    Additional command-line moxi options. Default: none
#  $cluster_url:
#    Membase cluster URL. Mandatory.
#  $usr:
#    Optional Membase user. Default: no auth
#  $pwd:
#    Optional Membase password. Default: no auth
#  $port_listen:
#    Local port to listen on. Default: '11211'
#  $default_bucket_name:
#    Name of the default bucket. Default: 'default'
#  $downstream_max,
#  $downstream_conn_max,
#  $downstream_conn_queue_timeout,
#  $downstream_timeout,
#  $wait_queue_timeout,
#  $connect_max_errors,
#  $connect_retry_interval,
#  $connect_timeout,
#  $auth_timeout,
#  $cycle:
#    Other Moxi parameters. See documentation.
#
# Sample Usage :
#  include moxi
#
class moxi (
  # Gentoo
  $rpmlocation = 'http://packages.couchbase.com/releases/1.8.1',
  $rpmbasename = 'moxi-server_x86_64_1.8.1', # without .rpm extension
  # init.d/moxi options - see moxi -h
  $options = '',
  $cron_restart = false,
  $cron_restart_hour = '04',
  $cron_restart_minute = fqdn_rand(60),
  # moxi-cluster.cfg options
  $cluster_url,
  # moxi.cfg options
  $usr = false,
  $pwd = false,
  $port_listen = '11211',
  $default_bucket_name = 'default',
  $downstream_max = '1024',
  $downstream_conn_max = '4',
  $downstream_conn_queue_timeout = '200',
  $downstream_timeout = '5000',
  $wait_queue_timeout = '200',
  $connect_max_errors = '5',
  $connect_retry_interval = '30000',
  $connect_timeout = '400',
  $auth_timeout = '100',
  $cycle = '200',
) {

  class { '::moxi::package':
    rpmlocation => $rpmlocation,
    rpmbasename => $rpmbasename,
    options     => $options,
  }

  # The main configuration files
  file { '/opt/moxi/etc/moxi.cfg':
    owner   => 'moxi',
    group   => 'moxi',
    content => template("${module_name}/moxi.cfg.erb"),
    require => Class['::moxi::package'],
    notify  => Service['moxi-server'],
  }
  file { '/opt/moxi/etc/moxi-cluster.cfg':
    owner   => 'moxi',
    group   => 'moxi',
    content => template("${module_name}/moxi-cluster.cfg.erb"),
    require => Class['::moxi::package'],
    notify  => Service['moxi-server'],
  }

  # We make the directory writeable by moxi so that we can dump pid, log,
  # sock... ugly, yeah.
  file { '/opt/moxi':
    ensure  => directory,
    owner   => 'moxi',
    group   => 'moxi',
    mode    => '0755',
    require => Class['::moxi::package'],
  }
  file { '/etc/logrotate.d/moxi':
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("${module_name}/logrotate.d/moxi.erb"),
  }

  # The package should take care of the user, this will tweak if needed
  user { 'moxi':
    comment => 'Moxi system user',
    home    => '/opt/moxi',
    shell   => '/sbin/nologin',
    system  => true,
  }

  service { 'moxi-server':
    ensure    => running,
    enable    => true,
    hasstatus => true,
    require   => Class['::moxi::package'],
  }

  if $cron_restart {
    cron { 'moxi-restart':
      command => '/sbin/service moxi-server restart >/dev/null',
      user    => 'root',
      hour    => $cron_restart_hour,
      minute  => $cron_restart_minute,
    }
  } else {
    cron { 'moxi-restart':
      user   => 'root',
      ensure => absent,
    }
  }

}

