# Class: ntp
#
#   This module manages the ntp service.
#
#   Jeff McCune <jeff@puppetlabs.com>
#   2011-02-23
#
#   Tested platforms:
#    - Debian 6.0 Squeeze
#    - CentOS 5.4
#    - Amazon Linux 2011.09
#    - FreeBSD 9.0
#    - Gentoo Linux
#
# Parameters:
#
#   $servers = [ '0.debian.pool.ntp.org iburst',
#                '1.debian.pool.ntp.org iburst',
#                '2.debian.pool.ntp.org iburst',
#                '3.debian.pool.ntp.org iburst', ]
#
#   $restrict = true
#     Whether to restrict ntp daemons from allowing others to use as a server.
#
#   $autoupdate = false
#     Whether to update the ntp package automatically or not.
#
#   $enable = true
#     Automatically start ntp deamon on boot.
#
# Actions:
#
#  Installs, configures, and manages the ntp service.
#
# Requires:
#
# Sample Usage:
#
#   class { "ntp":
#     servers    => [ 'time.apple.com' ],
#     autoupdate => false,
#   }
#
# [Remember: No empty lines between comments and class definition]
class ntp($servers=hiera('ntp_servers','UNSET'),
          $ensure=hiera('ntp_ensure','running'),
          $enable=hiera('ntp_enable',true),
          $restrict=hiera('ntp_restrict',true),
          $autoupdate=hiera('ntp_autoupdate',false),
          $broadcastclient=hiera('ntp_broadcastclient',false),
          $broadcast=hiera('ntp_broadcast','UNSET'),
          $multicastclient=hiera('ntp_multicastclient','UNSET'),
          $manycastclient=hiera('ntp_manycastclient','UNSET'),
          $manycastserver=hiera('ntp_manycastserver','UNSET')
) {

  if ! ($ensure in [ 'running', 'stopped' ]) {
    fail('ensure parameter must be running or stopped')
  }

  if $autoupdate == true {
    $package_ensure = latest
  } elsif $autoupdate == false {
    $package_ensure = present
  } else {
    fail('autoupdate parameter must be true or false')
  }

  case $::osfamily {
    Debian: {
      $supported  = true
      $pkg_name   = [ 'ntp' ]
      $svc_name   = 'ntp'
      $config     = '/etc/ntp.conf'
      $config_tpl = 'ntp.conf.debian.erb'
      if ($servers == 'UNSET') {
        $servers_real = [ '0.debian.pool.ntp.org iburst',
                          '1.debian.pool.ntp.org iburst',
                          '2.debian.pool.ntp.org iburst',
                          '3.debian.pool.ntp.org iburst', ]
      } else {
        $servers_real = $servers
      }
    }
    RedHat: {
      $supported  = true
      $pkg_name   = [ 'ntp' ]
      $svc_name   = 'ntpd'
      $config     = '/etc/ntp.conf'
      $config_tpl = 'ntp.conf.el.erb'
      if ($servers == 'UNSET') {
        $servers_real = [ '0.centos.pool.ntp.org',
                          '1.centos.pool.ntp.org',
                          '2.centos.pool.ntp.org', ]
      } else {
        $servers_real = $servers
      }
    }
    SuSE: {
      $supported  = true
      $pkg_name   = [ 'ntp' ]
      $svc_name   = 'ntp'
      $config     = '/etc/ntp.conf'
      $config_tpl = 'ntp.conf.suse.erb'
      if ($servers == 'UNSET') {
        $servers_real = [ '0.opensuse.pool.ntp.org',
                          '1.opensuse.pool.ntp.org',
                          '2.opensuse.pool.ntp.org',
                          '3.opensuse.pool.ntp.org', ]
      } else {
        $servers_real = $servers
      }
    }
    FreeBSD: {
      $supported  = true
      $pkg_name   = ['net/ntp']
      $svc_name   = 'ntpd'
      $config     = '/etc/ntp.conf'
      $config_tpl = 'ntp.conf.freebsd.erb'
      if ($servers == 'UNSET') {
        $servers_real = [ '0.freebsd.pool.ntp.org iburst maxpoll 9',
                          '1.freebsd.pool.ntp.org iburst maxpoll 9',
                          '2.freebsd.pool.ntp.org iburst maxpoll 9',
                          '3.freebsd.pool.ntp.org iburst maxpoll 9', ]
      } else {
        $servers_real = $servers
      }
    }
    default: {
      case $::operatingsystem {
        Gentoo: {
          $supported  = true
          $pkg_name   = [ 'net-misc/ntp' ]
          $svc_name   = 'ntpd'
          $config     = '/etc/ntp.conf'
          $config_tpl = 'ntp.conf.gentoo.erb'
          if ($servers == "UNSET") {
            $server_reals = [ '0.gentoo.pool.ntp.org',
                              '1.gentoo.pool.ntp.org',
                              '2.gentoo.pool.ntp.org',
                              '3.gentoo.pool.ntp.org', ]
          } else {
            $servers_real = $servers
          }

          # On Gentoo, the boot time is set through ntp-client
          # service, so handle it here.
          file { '/etc/conf.d/ntp-client':
            ensure  => file,
            owner   => 0,
            group   => 0,
            mode    => '0644',
            content => template("${module_name}/ntp-client.conf.gentoo.erb"),
            require => Package[$pkg_name],
          }

          service { 'ntp-client':
            ensure     => $ensure,
            enable     => $enable,
            hasstatus  => true,
            hasrestart => true,
            subscribe  => [ Package[$pkg_name], File['/etc/conf.d/ntp-client'] ],
          }
        }
        default: {
          fail("The ${module_name} module is not supported on ${::osfamily}/${::operatingsystem} based systems")
        }
      }
    }
  }

  package { 'ntp':
    ensure => $package_ensure,
    name   => $pkg_name,
  }

  file { $config:
    ensure  => file,
    owner   => 0,
    group   => 0,
    mode    => '0644',
    content => template("${module_name}/${config_tpl}"),
    require => Package[$pkg_name],
  }

  service { 'ntp':
    ensure     => $ensure,
    enable     => $enable,
    name       => $svc_name,
    hasstatus  => true,
    hasrestart => true,
    subscribe  => [ Package[$pkg_name], File[$config] ],
  }
}
