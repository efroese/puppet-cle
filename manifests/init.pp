# = Class: cle
#
# Install and start CLE from a tarball..
#
# == Parameters:
#
# $basedir:: The directory where cle will be installed.
#
# $user:: The user CLE will run as. It will also own the CLE files.
#
# $cle_tarball_url:: The URL to the tarball containing CLE
#
# $cle_tarball_path:: The path to the tarball containing CLE (optional, disables cle_tarball_url if defined)
#
# == Example Usage:
#
# class { 'cle':
#     cle_tarball_url => 'http://my.org/sakai/cle/releases/2-8-x.tgz,
#     user => 'sakaicle',
# }
#
# class { 'cle':
#     # THe tarball was delivered by the base image or deployment system
#     cle_tarball_path => '/files-cle/releases/2-8-x.tgz,
#     user => 'sakaicle',
# }
#
class cle (
    $basedir = "/usr/local",
    $user    = "sakaioae",
    $cle_tarball_url = "http://youforgot.to.configure/the/tarball/url.tgz",
    $cle_tarball_path = undef
    ){

    exec { 'fetch-cle-tarball':
        user => $cle_user,
        cwd  => $basedir,
        command => $cle_tarball_path ? {
            undef   => "curl -O cle-tarball.tgz ${cle_tarball_url}",
            default => "cp ${cle_tarball_path} .",
        },
        creates => "${basedir}/cle-tarball.tgz",
    }

    exec { 'unpack-cle-tarball':
        user => $cle_user,
        cwd  => $basedir,
        command => "tar xzvf cle-tarball.tgz",
        creates => "${basedir}/cle",
        require => Exec['fetch-cle-tarball'],
    }

    file { '/etc/init.d/sakaicle':
        mode => 0755,
        content => template('cle/sakaicle.sh.erb'),
    }

    service { 'sakaicle':
        enabled => true,
        ensure  => running,
        require => File['/etc/init.d/sakaicle']
    }
}