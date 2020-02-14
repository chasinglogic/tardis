# project name and programming language
project('com.github.chasinglogic.tardis', 'vala', 'c')

gettext_name = meson.project_name()
add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(gettext_name),
    language:'c'
)

i18n = import('i18n')

# Create a new executable, list the files we want to compile, list the dependencies we need, and install
executable(
    meson.project_name(),

    # Primary Classes
    'src/Application.vala',
    'src/Backups.vala',
    'src/BackupTargetManager.vala',
    'src/BackupTarget.vala',
    'src/BackupStatus.vala',
    'src/Utils.vala',

    # Custom Widgets
    'src/Widgets/HeaderBar.vala',
    'src/Widgets/SettingToggler.vala',
    'src/Widgets/DriveStatus.vala',
    'src/Widgets/MainView.vala',

    dependencies: [
      dependency('gtk+-3.0'),
      dependency('granite'),
      dependency('gio-2.0'),
      dependency('json-glib-1.0'),
    ],

    install: true
)

#Install our .desktop file so the Applications Menu will see it
install_data(
    join_paths('data', meson.project_name() + '.desktop'),
    install_dir: join_paths(get_option('datadir'), 'applications')
)

#Install our .appdata.xml file so AppCenter will see it
install_data(
    join_paths('data', meson.project_name() + '.appdata.xml'),
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)

icon_sizes = ['48', '64', '128']
icon_names = [meson.project_name(), meson.project_name() + '.add-backup-drive']
foreach i : icon_sizes
  foreach name : icon_names
      install_data(
          join_paths('data', 'icons', i, name + '.svg'),
          install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
      )

      install_data(
          join_paths('data', 'icons', i, name + '.svg'),
          install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i + '@2', 'apps')
      )
  endforeach
endforeach

install_data(
  join_paths('data', meson.project_name() + '.gschema.xml'),
  install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas'),
  rename: meson.project_name() + '.gschema.xml'
)
