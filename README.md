
## CatFrida

CatFrida is a macOS tool for inspecting a running iOS app.

Building with [frida-swift](https://github.com/frida/frida-swift), CatFrida provide an awesome easy way to dive into an app.

[Download CatFrida.app](https://github.com/neil-wu/CatFrida/releases)

[Screenshots](./Screenshots/)


## Features

- [x] App basic info
- [x] List all loaded modules
- [x] Dumpdecrypt module
- [x] List module's symbols
- [x] File explorer (either app bundle or document)
- [x] Download app files
- [x] Class dump
- [x] UI description
- [x] Capture Alamofire HTTP requests
- [x] Support load custom script


## Usage

You need a jailbroken iOS device with frida server installed. Check the following link to see [how to install frida on jailbroken device?](https://frida.re/docs/ios/#with-jailbreak)

1. Connect your jailbroken iOS device with macbook

2. Run CatFrida.app

Enjoy :)

The application is not code-signed. You can sign it manually.
```
xcode-select --install
codesign --force --deep --sign - /Applications/CatFrida.app
```

## Build

Currently, CatFrida use frida-core 14.2.3. Since the binary file is too large, the git project doesn't include it. You can install it manually by the following steps:

1. Click to download [frida-core-devkit-14.2.3-macos-x86_64.tar.xz](https://github.com/frida/frida/releases/download/14.2.3/frida-core-devkit-14.2.3-macos-x86_64.tar.xz)

2. Extract `tar -xvf frida-core-devkit-14.2.3-macos-x86_64.tar.xz`

3. Copy `frida-core.h` and `libfrida-core.a` to `CatFrida/FridaBridge/CFrida/macos-x86_64/`

4. `pod install`

5. Open CatFrida.xcworkspace and build


## Scripts

CatFrida load script in `CatFrida/Scripts/_agent.js`. It was built by project [CatFridaAgent](https://github.com/neil-wu/CatFridaAgent). You can modify CatFridaAgent to add your own script.

Some script files are from [passionfruit](https://github.com/chaitin/passionfruit)

It also include my own project [FridaHookSwiftAlamofire](https://github.com/neil-wu/FridaHookSwiftAlamofire) to capture Alamofire HTTP requests.

## License

MIT






