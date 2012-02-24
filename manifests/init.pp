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
#     cle_tarball_url => 'http://my.org/sakai/cle/releases/2-8-x.tbz,
#     user => 'sakaicle',
# }
#
# class { 'cle':
#     # THe tarball was delivered by the base image or deployment system
#     cle_tarball_path => '/files-cle/releases/2-8-x.tbz,
#     user => 'sakaicle',
# }
#
class cle (
    $basedir                      = "/usr/local/sakaicle",
    $tomcat_home                  = "/usr/local/sakaicle/tomcat",
    $user                         = "sakaioae",
    $cle_tarball_url              = "http://youforgot.to.configure/the/tarball/url.tbz",
    $cle_tarball_path             = undef,
    $sakai_properties_template    = undef,
    $local_properties_template    = undef,
    $instance_properties_template = undef,
    $linktool_salt                = undef,
    $linktool_privkey             = undef
    ){

    if !defined(File[$basedir]) {
        file { $basedir:
            ensure => directory,
            owner  => $user,
        }
    }

    exec { 'fetch-cle-tarball':
        user => $cle_user,
        command => $cle_tarball_path ? {
            undef   => "curl -o ${$basedir}/cle-tarball.tbz ${cle_tarball_url}",
            default => "cp ${cle_tarball_path} .",
        },
        creates => "${basedir}/cle-tarball.tbz",
        timeout => 0,
    }

    exec { 'unpack-cle-tarball':
        user => $cle_user,
        cwd  => $tomcat_home,
        command => "tar xjvf ../cle-tarball.tbz",
        creates => "${tomcat_home}/webapps/sakai-chat-tool.war",
        require => Exec['fetch-cle-tarball'],
    }

    file { "${tomcat_home}/sakai/sakai.properties":
        owner => $user,
        group => $user,
        mode  => 0644,
        content => template($sakai_properties_template),
        require => Exec['unpack-cle-tarball'],
    }

    file { "${tomcat_home}/sakai/local.properties":
        owner => $user,
        group => $user,
        mode  => 0644,
        content => $instance_properties_template ? {
            undef   => '# managed by puppet. \$local_properties_template not specified',
            default => template($instance_properties_template),
        },
        require => Exec['unpack-cle-tarball'],
    }

    file { "${tomcat_home}/sakai/instance.properties":
        owner => $user,
        group => $user,
        mode  => 0644,
        content => $local_properties_template ? {
            undef   => '# managed by puppet. \$instance_properties_template not specified',
            default => template($local_properties_template),
        },
        require => Exec['unpack-cle-tarball'],
    }

    if $linktool_privkey != undef {
        file { "${basedir}/cle/tomcat/sakai/sakai.rutgers.linktool.privkey":
            owner => $user,
            group => $user,
            mode  => 0644,
            content => $linktool_privkey,
            require => Exec['unpack-cle-tarball'],
        }
    }

    if $linktool_salt != undef {
        file { "${basedir}/cle/tomcat/sakai/sakai.rutgers.linktool.salt":
            owner => $user,
            group => $user,
            mode  => 0644,
            content => $linktool_salt,
            require => Exec['unpack-cle-tarball'],
        }
    }

    file { '/etc/init.d/sakaicle':
        mode => 0755,
        content => template('cle/sakaicle.sh.erb'),
    }

    service { 'sakaicle':
        enable  => true,
        ensure  => running,
        require => [ File['/etc/init.d/sakaicle'],  File["${tomcat_home}/sakai/sakai.properties"], ],
    }
}