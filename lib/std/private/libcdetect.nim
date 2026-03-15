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

  import std/strscans

  proc quotedOrWord(input: string; strVal: var string; start: int): int =
    ## Matches a quoted string or unquoted word (until space/end).
    if start < input.len and input[start] == '"':
      var i = start + 1
      while i < input.len and input[i] != '"': inc i
      if i < input.len:
        strVal = input[start + 1 ..< i]
        return i + 1 - start
    else:
      var i = start
      while i < input.len and input[i] != ' ': inc i
      if i > start:
        strVal = input[start ..< i]
        return i - start

  const
    cc = block:
      var prefix, nimCC: string
      discard scanf(querySetting(SingleValueSetting.commandLine),
                    "$*--gcc.exe:${quotedOrWord}", prefix, nimCC)
      if nimCC.len > 0: nimCC else: "${CC:-cc}"
    # gorgeEx is the only way to query C preprocessor macros at compile time
    isGlibc* = gorgeEx(
      "printf '#include <features.h>\\n' | " & cc &
        " -E -dM - 2>/dev/null | grep -q __GLIBC__"
    )[1] == 0
else:
  const isGlibc* = false
