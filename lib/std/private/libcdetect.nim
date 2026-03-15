## Detect the C library at compile time.
##
## Uses the C preprocessor via `gorgeEx` so that `isGlibc` is a true
## compile-time constant.  This means `when isGlibc:` works and dead
## branches are eliminated before code generation — no linker issues,
## no runtime overhead.
##
## The C compiler is obtained from Nim's ``--gcc.exe`` flag (via
## ``compilesettings.commandLine``), falling back to ``$CC`` then ``cc``.
##
## Usage:
##   import std/private/libcdetect
##   when isGlibc:
##     # glibc-only code — not even compiled on musl

when defined(linux):
  import std/compilesettings

  import std/strutils

  func extractGccExe(cmdLine: string): string {.compileTime.} =
    ## Extract ``--gcc.exe:VALUE`` from the Nim command line.
    const flag = "--gcc.exe:"
    var i = cmdLine.find(flag)
    if i < 0: return ""
    i += flag.len
    # Handle quoted values
    if i < cmdLine.len and cmdLine[i] == '"':
      inc i
      let j = cmdLine.find('"', i)
      if j >= 0: return cmdLine[i ..< j]
      return cmdLine[i .. ^1]
    # Unquoted: take until whitespace
    var j = i
    while j < cmdLine.len and cmdLine[j] != ' ': inc j
    return cmdLine[i ..< j]

  const
    nimCC = extractGccExe(querySetting(SingleValueSetting.commandLine))
    cc = if nimCC.len > 0: nimCC else: "${CC:-cc}"
    isGlibc* = gorgeEx(
      "printf '#include <features.h>\\n' | " & cc &
        " -E -dM - 2>/dev/null | grep -q __GLIBC__"
    )[1] == 0
else:
  const isGlibc* = false
