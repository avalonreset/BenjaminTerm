BenjaminTerm Third-Party Notices
================================

BenjaminTerm is a custom distribution/fork of WezTerm.
This repository and its distributions include third-party components with their
own license terms and attribution requirements.

Primary project license
-----------------------
- WezTerm/BenjaminTerm codebase license: MIT
- See: `LICENSE.md`

Bundled font licenses
---------------------
- JetBrains Mono, Roboto, Noto Color Emoji, and Symbols Nerd Font Mono are
  distributed under OFL-family terms as documented in:
  - `assets/fonts/LICENSE_OFL.txt`
  - `assets/fonts/LICENSE_POWERLINE_EXTRA.txt`

Windows runtime-distributed components
--------------------------------------
- ANGLE libraries (`libEGL.dll`, `libGLESv2.dll`)
  - License text in this repository: `licenses/ANGLE.md`

- Microsoft Terminal conhost artifacts (`conpty.dll`, `OpenConsole.exe`)
  - Attribution and source notes:
    - `assets/windows/conhost/README.md`
  - These artifacts are documented there as MIT-licensed upstream components.

- Mesa software OpenGL shim (`mesa/opengl32.dll`)
  - Attribution and source notes:
    - `assets/windows/mesa/README.md`
  - Mesa licensing is described by upstream as a set of permissive licenses.

Practical compliance note
-------------------------
When redistributing BenjaminTerm binaries/installers, include:
- `LICENSE.md`
- this file (`licenses/THIRD_PARTY_NOTICES.md`)
- `licenses/ANGLE.md`
- `assets/fonts/LICENSE_OFL.txt`
- `assets/fonts/LICENSE_POWERLINE_EXTRA.txt`
- `assets/windows/conhost/README.md`
- `assets/windows/mesa/README.md`
