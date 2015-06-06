# Public: Installs a version of Terraform
#
# Params:
#
#  ensure  -- must be present or absent, default present
#  root    -- the path to install terraform to, see terraform::params for default
#  user    -- the user to install terraform as, see terraform::params for default
#  version -- the version of terraform to ensure, see terraform::params for default

class terraform(
  $ensure  = present,
  $root    = $terraform::params::root,
  $user    = $terraform::params::user,
  $version = $terraform::params::version,
) inherits terraform::params {

  case $ensure {
    present: {
      # get the download URI
      $download_uri = "https://dl.bintray.com/mitchellh/terraform/terraform_${version}_${terraform::params::_real_platform}.zip?direct"

      # the dir inside the zipball uses the major version number segment
      $major_version = split($version, '[.]')
      $extracted_dirname = $major_version[0]

      $install_command = join([
        # blow away any previous attempts
        "rm -rf /tmp/terraform* /tmp/${extracted_dirname}",
        # download the zip to tmp
        "curl -L ${download_uri} > /tmp/terraform-v${version}.zip",
        # extract the zip to tmp spot
        'mkdir /tmp/terraform',
        "unzip -o /tmp/terraform-v${version}.zip -d /tmp/terraform",
        # blow away an existing version if there is one
        "rm -rf ${root}",
        # move the directory to the root
        "mv /tmp/terraform ${root}",
        # chown it
        "chown -R ${user} ${root}"
      ], ' && ')

      exec {
        "install terraform v${version}":
          command => $install_command,
          unless  => "test -x ${root}/terraform && ${root}/terraform -v | grep '\\bv${version}\\b'",
          user    => $user,
      }

      if $::operatingsystem == 'Darwin' {
        include boxen::config

        boxen::env_script { 'terraform':
          content  => template('terraform/env.sh.erb'),
          priority => 'lower',
        }

        file { "${boxen::config::envdir}/terraform.sh":
          ensure => absent,
        }
      }
    }

    absent: {
      file { $root:
        ensure  => absent,
        recurse => true,
        force   => true,
      }
    }

    default: {
      fail('Ensure must be present or absent')
    }
  }
}
