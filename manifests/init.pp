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
# $sakai_properties_template:: The path fo the template used to render sakai/sakai.properties (optional)
#
# $local_properties_template:: The path fo the template used to render sakai/local.properties (optional)
#
# $instance_properties_template:: The path fo the template used to render sakai/instance.properties (optional)
#
# $linktool_salt:: The salt for the sakai rutgers linktool
#
# $linktool_privkey:: The private key for the sakai rutgers linktool
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

    file { "${basedir}/cle/tomcat/sakai/sakai.properties":
        owner => $user,
        group => $user,
        mode  => 0644,
        content => template($sakai_properties_template),
    }

    file { "${basedir}/cle/tomcat/sakai/local.properties":
        owner => $user,
        group => $user,
        mode  => 0644,
        content => template($local_properties_template),
    }

    file { "${basedir}/cle/tomcat/sakai/instance.properties":
        owner => $user,
        group => $user,
        mode  => 0644,
        content => template($instance_properties_template),
    }

    file { "${basedir}/cle/tomcat/sakai/sakai.rutgers.linktool.privkey":
        owner => $user,
        group => $user,
        mode  => 0644,
        content => $linktool_privkey,
    }

    file { "${basedir}/cle/tomcat/sakai/sakai.rutgers.linktool.salt":
        owner => $user,
        group => $user,
        mode  => 0644,
        content => $linktool_salt,
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