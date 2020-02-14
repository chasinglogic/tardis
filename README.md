<div align="center">
  <span align="center"> <img width="80" height="70" class="center" src="https://github.com/chasinglogic/tardis/blob/master/data/icons/128/com.github.chasinglogic.tardis.svg" alt="Icon"></span>
  <h1 align="center">Tardis</h1>
  <h3 align="center">A simple backup application for Elementary OS</h3>

  <a href="https://appcenter.elementary.io/com.github.chasinglogic.tardis"><img src="https://appcenter.elementary.io/badge.svg?new" alt="Get it on AppCenter" /></a>
</div>

## Installation

<a href="https://appcenter.elementary.io/com.github.chasinglogic.tardis"><img src="https://appcenter.elementary.io/badge.svg?new" alt="Get it on AppCenter" /></a>

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
