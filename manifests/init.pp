# = Class: cle
#
# Unpack a tarball over Tomcat to install Sakai CLE
#
# == Requires:
#
# Module['tomcat6']
#
# == Parameters:
#
# $basedir:: Everything gets installed below this directory.
#
# $user:: The user CLE will run as. It will also own the CLE files.
#
# $cle_tarball_url:: The URL to the tarball containing the tomcat overlay for CLE
#
# $cle_tarball_path:: The path to the tarball containing tomcat overlay for CLE (optional, disables cle_tarball_url if defined)
#
# $server_id:: The CLE server_id
#
# $configuration_xml_template:: Template used to render sakai/sakai-configuration.xml
#
# $sakai_properties_template:: The path to the template used to render sakai/sakai.properties (optional)
#
# $local_properties_template:: The path to the template used to render sakai/local.properties (optional)
#
# $instance_properties_template:: The path to the template used to render sakai/instance.properties (optional)
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
#     # The tarball was delivered by the base image or deployment system
#     cle_tarball_path => '/files-cle/releases/2-8-x.tbz,
#     user => 'sakaicle',
#     server_id => 'cle0',
# }
#
class cle (
    $basedir                      = "/usr/local/sakaicle",
    $tomcat_home                  = "/usr/local/sakaicle/tomcat",
    $user                         = "sakaioae",
    $cle_tarball_url              = "http://youforgot.to.configure/the/tarball/url.tbz",
    $cle_tarball_path             = undef,
    $server_id                    = 'cle1',
    $configuration_xml_template   = undef,
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

    # /usr/local/sakaicle/sakai/
    $sakaidir = "${basedir}/sakai"
    file { $sakaidir:
        ensure => directory,
        owner  => $user,
    }

    # To avoid this command, create ${basedir}/cle-tarball.tbz before the puppet run.
    exec { 'fetch-cle-tarball':
        user => $user,
        # Either download or copy the tarball
        command => $cle_tarball_path ? {
            undef   => "curl -o ${$basedir}/cle-tarball.tbz ${cle_tarball_url}",
            default => "cp ${cle_tarball_path} .",
        },
        creates => "${basedir}/cle-tarball.tbz",
        timeout => 0,
    }

    tomcat::overlay { 'cle-overlay':
        tomcat_home  => $tomcat_home,
        tarball_path => $cle_tarball_path,
        creates      => "${tomcat_home}/webapps/sakai-chat-tool.war",
        user         => $user,
        require      => Exec['fetch-cle-tarball'],
        notify       => Service['tomcat'],
    }

    # /usr/local/sakaicle/tomcat/sakai -> /usr/local/sakaicle/sakai
    file { "${tomcat_home}/sakai":
        ensure  => link,
        target  => $sakaidir,
        require => Exec['unpack-cle-tarball'],
    }

    if $configuration_xml_template != undef {
        file { "${sakaidir}/sakai-configuration.xml":
            owner => $user,
            group => $user,
            mode  => 0644,
            content => template($configuration_xml_template),
            require => Exec['unpack-cle-tarball'],
            notify  => Service['tomcat'],
        }
    }

    file { "${sakaidir}/sakai.properties":
        owner => $user,
        group => $user,
        mode  => 0644,
        content => template($sakai_properties_template),
        require => Exec['unpack-cle-tarball'],
        notify  => Service['tomcat'],
    }

    file { "${sakaidir}/local.properties":
        owner => $user,
        group => $user,
        mode  => 0644,
        content => $instance_properties_template ? {
            undef   => '# managed by puppet. \$local_properties_template not specified',
            default => template($instance_properties_template),
        },
        require => Exec['unpack-cle-tarball'],
        notify  => Service['tomcat'],
    }

    if $instance_properties_template != undef {
        file { "${sakaidir}/instance.properties":
            owner => $user,
            group => $user,
            mode  => 0644,
            content => $local_properties_template ? {
                undef   => '# managed by puppet. \$instance_properties_template not specified',
                default => template($local_properties_template),
            },
            require => Exec['unpack-cle-tarball'],
            notify  => Service['tomcat'],
        }
    }

    if $linktool_privkey != undef {
        file { "${sakaidir}/sakai.rutgers.linktool.privkey":
            owner => $user,
            group => $user,
            mode  => 0644,
            content => $linktool_privkey,
            require => Exec['unpack-cle-tarball'],
            notify  => Service['tomcat'],
        }
    }

    if $linktool_salt != undef {
        file { "${sakaidir}/sakai.rutgers.linktool.salt":
            owner => $user,
            group => $user,
            mode  => 0644,
            content => $linktool_salt,
            require => Exec['unpack-cle-tarball'],
            notify  => Service['tomcat'],
        }
    }
}