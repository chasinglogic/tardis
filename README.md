<div align="center">
  <span align="center"> <img width="80" height="70" class="center" src="https://github.com/chasinglogic/tardis/blob/master/data/icons/128/com.github.chasinglogic.tardis.svg" alt="Icon"></span>
  <h1 align="center">Tardis</h1>
  <h3 align="center">A simple backup application for elementary OS</h3>

  <a href="https://appcenter.elementary.io/com.github.chasinglogic.tardis"><img src="https://appcenter.elementary.io/badge.svg?new" alt="Get it on AppCenter" /></a>
</div>

## Usage

### Adding a Backup Drive

![gif on how to add a backup drive](https://github.com/chasinglogic/tardis/blob/master/data/gifs/add_a_new_backup_drive.gif)

### Running a Backup


![gif on how to run a backup](https://github.com/chasinglogic/tardis/blob/master/data/gifs/backing_up.gif)

## Building

The following dependencies are required to build Tardis:

    - libgtk-3-dev
    - libjson-glib-dev
    - libgranite-dev
    - rsync
    - meson
    - valac >= 0.40.3

Use the following commands to compile Tardis:

```
meson build
ninja -C build
```

To install your freshly built version:

```
sudo ninja -C build install
```
