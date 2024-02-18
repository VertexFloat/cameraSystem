<div id="top"></div>
<br/>
<div align="center">
  <a href="https://github.com/VertexFloat/cameraSystem">
    <img src="screenshots/icon.png" alt="Logo" width="128" height="128">
  </a>
  <h3>Camera System</h3>
  <p>
    Farming Simulator 22 Modification
    <br/>
    <br/>
    <a href="https://github.com/VertexFloat/cameraSystem/issues">Report Bug</a>
    ·
    <a href="https://github.com/VertexFloat/cameraSystem/issues">Request Feature</a>
    ·
    <a href="https://github.com/VertexFloat/cameraSystem/blob/main/CHANGELOG.md">Changelog</a>
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
As standard, some of the originally available vehicles and implements were equipped with camera configurations.
<br/>
<br/>
Change camera system mode (off/on) - "z" key (default)
<br/>
Next/previous camera - "left shift + k/m" keys (default)

<p align="right">&#x2191 <a href="#top">back to top</a></p>

## Getting started

If you want to install latest official version, you can [download](https://www.farming-simulator.com/mod.php?mod_id=274634&title=fs2022) it like other mods.
<br/>

### Prerequisites

* [Farming Simulator 22 (PC)](https://www.farming-simulator.com/buy-now.php?platform=pc&code=VertexFloat)
* [Farming Simulator 22 (PC-Download)](https://www.farming-simulator.com/buy-now.php?platform=pcdigital&code=VertexFloat)

### Installation

1. Clone the repo
```sh
git clone https://github.com/VertexFloat/cameraSystem
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

### Vehicle Integration

You can just copy code below and fill it with appropriate data type. (<a href="https://github.com/VertexFloat/cameraSystem/blob/main/VEHICLES.md">Here</a> you will find a list of vehicles integrated by default)

```xml
<cameraSystem>
  <cameraConfigurations>
    <cameraConfiguration name="string" price="integer">
      <camera node="node" name="string" fov="float" nearClip="float" farClip="float" activeFunc="string" rotation="x y z" translation="x y z"/>
    </cameraConfiguration>
  </cameraConfigurations>
</cameraSystem>
```

| Tag | Attribute | Description | Default | isRequired |
| --- | --- | --- | :---: | :---: |
| cameraConfiguration | name | translation key for configuration name or configuration name | - | - |
| cameraConfiguration | price | price of configuration | - | - |
| camera | node | node where camera will be linked, node index or i3dMapping | - | **true** |
| camera | name | translation key for camera name or camera name | Untitled | false |
| camera | fov | camera field of view | 60 | false |
| camera | nearClip | camera near clip | 0.01 | false |
| camera | farClip | camera far clip | 10000 | false |
| camera | activeFunc | function which return boolean whether camera is active or not | - | false |
| camera | rotation | camera rotation | - | false |
| camera | translation | camera translation | - | false |

By default, the available camera names are:

| Key | Text |
| --- | --- |
| $l10n_ui_cameraSystem_nameRear | Rear |
| $l10n_ui_cameraSystem_namePipe | Pipe |
| $l10n_ui_cameraSystem_nameWork | Work area |

The available activation functions are:

| Name | Description | Required Specialization |
| --- | --- | ---: |
| getCameraSystemIsReverse | if the vehicle is going backwards, it returns true | Drivable |
| getCameraSystemIsLowered | if the vehicle is lowered, it returns true | Attachable |
| getCameraSystemIsUnfolded | if the vehicle is unfolded, it returns true | Foldable |
| getCameraSystemIsPipeUnfolded | if the vehicle pipe is unfolded, it returns true | Pipe |

You can also add an objectChange to configuration

```xml
<objectChange node="node" visibilityActive="boolean" visibilityInactive="boolean"/>
```

| Tag | Attribute | Description | Default | isRequired |
| --- | --- | --- | :---: | :---: |
| objectChange | node | object node which visibility will be affect, node index or i3dMapping | - | **true** |
| objectChange | visibilityActive | whether or not object is visible in this configuration | - | - |
| objectChange | visibilityInactive | whether or not object is visible all time | - | - |

You can add configurations to **mods/internalMods/dlcs/inGame** to default integration file ***CameraSystemDefaultVehicleData.xml*** as shown below

```xml
<cameraSystemDefaultVehicleData>
  <vehicles>
    <vehicle xmlFilename="string" price="integer">
      <cameras>
        <camera nodeName="string" visibilityNodeName="string" name="string" fov="float" nearClip="float" farClip="float" activeFunc="string" rotation="x y z" translation="x y z"/>
      </cameras>
    </vehicle>
  </vehicles>
</cameraSystemDefaultVehicleData>
```

**Rest of camera attributes are the same as shown above**

| Tag | Attribute | Description | Default | isRequired |
| --- | --- | --- | :---: | :---: |
| vehicle | xmlFilename | path to vehicle xml file | - | **true** |
| vehicle | price | price of configuration | 500 | - |
| camera | nodeName | name of i3dMapping where camera will be linked | - | **true** |
| camera | visibilityNodeName | name of i3dMapping node that visibility is needed | - | - |

Prefixes for specific paths:

| Path | Prefix | Example | isRequired |
| --- | --- | --- | :---: |
| mods | mod | *mod/FS22_caseIHMagnum7240Pro/magnum7240Pro.xml* | **true** |
| dlcs | dlc | *dlc/claasSaddleTracPack/vehicles/claas/xerion4000.xml* | **true** |
| internalMods | internal | *internal/arena/caseIH/axialFlow250/axialFlow250.xml* | **true** |
| inGame | data | *data/vehicles/claas/arion600/arion600.xml* | **true** |

<p align="right">&#x2191 <a href="#top">back to top</a></p>

## Usage

<img src="screenshots/screenShot (2).png" alt="screenshot">
<img src="screenshots/screenShot (3).png" alt="screenshot">
<img src="screenshots/screenShot (4).png" alt="screenshot">
<img src="screenshots/screenShot (5).png" alt="screenshot">
<img src="screenshots/screenShot (6).png" alt="screenshot">

<p align="right">&#x2191 <a href="#top">back to top</a></p>

## License

Distributed under the GPL-3.0 license. See [LICENSE](https://github.com/VertexFloat/cameraSystem/blob/main/LICENSE) for more information.

<p align="right">&#x2191 <a href="#top">back to top</a></p>

## Acknowledgments

* [Choose an Open Source License](https://choosealicense.com)
* [Best README Template](https://github.com/othneildrew/Best-README-Template)
* [Security camera icons created by Prosymbols Premium - Flaticon](https://www.flaticon.com/free-icons/security-camera)

<p align="right">&#x2191 <a href="#top">back to top</a></p>
