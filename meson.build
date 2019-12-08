# project name and programming language
project('com.github.chasinglogic.tardis', 'vala', 'c')

gettext_name = meson.project_name()
add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(gettext_name),
    language:'c'
)

# Create a new executable, list the files we want to compile, list the dependencies we need, and install
executable(
    meson.project_name(),

    # Primary Classes
    'src/Application.vala',
    'src/Settings.vala',

    # Views
    'src/Views/DriveSelectionView.vala',

    # Custom Widgets
    'src/Widgets/SyncFoldersWidget.vala',
    'src/Widgets/BackupStatus.vala',
    'src/Widgets/BackupSafe.vala',
    'src/Widgets/Row.vala',

    dependencies: [
      dependency('gtk+-3.0'),
      dependency('granite'),
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

install_data(
  join_paths('data', meson.project_name() + '.gschema.xml'),
  install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas'),
  rename: meson.project_name() + '.gschema.xml'
)
