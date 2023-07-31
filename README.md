<div id="top"></div>
<br/>
<div align="center">
  <a href="https://github.com/4c65736975/cameraSystem">
    <img src="screenshots/icon.png" alt="Logo" width="128" height="128">
  </a>
  <h3>Camera System</h3>
  <p>
    Farming Simulator 22 Modification
    <br/>
    <br/>
    <a href="https://github.com/4c65736975/cameraSystem/issues">Report Bug</a>
    ·
    <a href="https://github.com/4c65736975/cameraSystem/issues">Request Feature</a>
  </p>
</div>
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li>
          <a href="#prerequisites">Prerequisites</a>
        </li>
        <li>
          <a href="#installation">Installation</a>
        </li>
        <li>
          <a href="#improvements">Improvements</a>
        </li>
        <li>
          <a href="#vehicle-integration">Vehicle Integration</a>
        </li>
      </ul>
    </li>
    <li>
      <a href="#usage">Usage</a>
    </li>
    <li>
      <a href="#license">License</a>
    </li>
    <li>
      <a href="#acknowledgments">Acknowledgments</a>
    </li>
  </ol>
</details>

## About the project

<img src="screenshots/screenShot (1).png" alt="screenshot">

This modification gives the possibility of adding cameras, e.g. a discharge pipe camera or a rear view camera. You can easily switch between added cameras which are displayed as HUD.
As standard, some of the originally available vehicles were equipped with camera configurations.
<br/>
<br/>
Change camera system mode (off/always on/only when reversing) - "z" key (default)
<br/>
Next/previous camera - "left shift + k/m" keys (default)

ATTENTION!
- to activate the camera system, the vehicle must have their configuration added,
- the image quality of the cameras is the highest I could set, so please bear with me. (The quality of the camera also depends on your graphics settings, it is also possible to manually improve it, details are below)

<p align="right">&#x2191 <a href="#top">back to top</a></p>

## Getting started

If you want to install latest official version, you can [download](https://www.farming-simulator.com/mod.php?mod_id=274634&title=fs2022) it like other mods.
<br/>

### Prerequisites

* [Farming Simulator 22 (PC)](https://www.farming-simulator.com/buy-now.php?platform=pc&code=DANIO)
* [Farming Simulator 22 (PC-Download)](https://www.farming-simulator.com/buy-now.php?platform=pcdigital&code=DANIO)

### Installation

1. Clone the repo
```sh
git clone https://github.com/4c65736975/cameraSystem
```
2. Open cloned folder.
3. Run modInstaller.exe.
4. That"s it, if everything went as it should, you can delete cloned folder.
5. Run the game and have a nice time.

or

1. Click code, download zip.
2. Extract downloaded file.
3. Run modInstaller.exe.
4. That"s it, if everything went as it should, you can delete downloaded folder and zip file.
5. Run the game and have a nice time.

### Improvements

You can improve camera quality (dust, effects) by <font color="#f54040">changing</font> the code as shown below. <font color="#f54040">Note that with this change you will get a lua error from time to time, but the game will run fine.</font>

```lua
src/gui/hud/elements/CameraRenderElement.lua

local development = false -- change to true
```

### Vehicle Integration

You can just copy code below and fill it with appropriate data type. (<a href="https://github.com/4c65736975/cameraSystem/blob/main/VEHICLES.md">Here</a> you will find a list of vehicles integrated by default)

```xml
<cameraSystem>
  <cameraConfigurations>
    <cameraConfiguration name="string" price="integer">
      <camera node="node" name="string" fov="float" rotation="x y z" translation="x y z"/>
    </cameraConfiguration>
  </cameraConfigurations>
</cameraSystem>

<!--
cameraConfiguration -> name -> translation key for configuration name e.g. $l10n_configuration_valueOne
cameraConfiguration -> price -> price of configuration e.g. "500"
camera -> node -> node where camera will be linked, node index e.g. "0>1" or i3dMapping e.g. "vehicle_vis" - $REQUIRED
camera -> name -> translation key for camera name e.g $l10n_camera_front_left_wheel - default camera name when not defined is "Untitled"
camera -> fov -> camera field of view - default is "60"
camera -> rotation -> camera rotation based on camera node e.g. "0 90 0"
camera -> translation -> camera translation based on camera node e.g. "0 5 0"

Default available camera names is: (name - translation key)
"Rear" -> $l10n_cameraSystem_rear_camera_name
"Pipe" -> $l10n_cameraSystem_pipe_camera_name
"Work area" -> $l10n_cameraSystem_work_camera_name
-->
```

You can also add an objectChange (you decide whether the defined object should be hidden in this configuration or shown, it can also be visible all the time)

```xml
<cameraConfiguration name="$l10n_configuration_valueYes" price="100">
  <camera node="0>1"/>
  <objectChange node="node" visibilityActive="boolean" visibilityInactive="boolean"/>
</cameraConfiguration>

<!--
objectChange -> node -> object node which visibility will be affect, node index e.g. "0>4>5" or i3dMapping e.g. "camera_node_top"
objectChange -> visibilityActive -> whether or not object from object node is visible in this configuration
objectChange -> visibilityInactive -> whether or not object from object node is visible all time
-->
```

You can add as many configurations and cameras as the game allows you.

```xml
<cameraSystem>
  <cameraConfigurations>
    <cameraConfiguration name="$l10n_configuration_valueNo" price="0"/>

    <cameraConfiguration name="$l10n_configuration_valueOne" price="200">
      <camera node="magnum7240pro_main_component1"/>
    </cameraConfiguration>

    <cameraConfiguration name="$l10n_configuration_valueAll" price="500">
      <camera node="magnum7240pro_main_component1" fov="75" translation="0 3.2 0" rotation="-25 180 0"/>
      <camera node="0>1" name="$l10n_cameraSystem_rear_camera_name" rotation="0 180 0"/>

      <objectChange node="0>0|17" visibilityActive="true" visibilityInactive="false"/>
    </cameraConfiguration>
  </cameraConfigurations>
</cameraSystem>
```

<p align="right">&#x2191 <a href="#top">back to top</a></p>

## Usage

<img src="screenshots/screenShot (2).png" alt="screenshot">
<img src="screenshots/screenShot (3).png" alt="screenshot">
<img src="screenshots/screenShot (4).png" alt="screenshot">
<img src="screenshots/screenShot (5).png" alt="screenshot">
<img src="screenshots/screenShot (6).png" alt="screenshot">

<p align="right">&#x2191 <a href="#top">back to top</a></p>

## License

Distributed under the GPL-3.0 license. See [LICENSE](https://github.com/4c65736975/cameraSystem/blob/main/LICENSE) for more information.

<p align="right">&#x2191 <a href="#top">back to top</a></p>

## Acknowledgments

* [Choose an Open Source License](https://choosealicense.com)
* [Best README Template](https://github.com/othneildrew/Best-README-Template)
* [Security camera icons created by Prosymbols Premium - Flaticon](https://www.flaticon.com/free-icons/security-camera)

<p align="right">&#x2191 <a href="#top">back to top</a></p>
