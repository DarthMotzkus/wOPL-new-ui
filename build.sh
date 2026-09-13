#!/usr/bin/env bash
#
# Build this fork and put the ELF in dist/.
#
#   ./build.sh              clean build -> dist/wOPL-new-ui-<sha>-<YYYY-MM-DD>.ELF
#   ./build.sh --no-clean   skip the clean, for iterating on a source change
#
# The toolchain is ps2dev v2.0.0 under /opt/toolchains/ps2dev; export PS2DEV to
# build against an install somewhere else. Full output is kept in build.log.
# See docs/build-pipeline.md.

set -euo pipefail
cd "$(dirname "$0")"

no_clean=0
for arg in "$@"; do
    case "$arg" in
        --no-clean) no_clean=1 ;;
        -h | --help)
            sed -n '3,6p' "$0" | cut -c3-
            exit 0
            ;;
        *)
            echo "build.sh: unknown argument '$arg' (try --help)" >&2
            exit 2
            ;;
    esac
done

die() {
    echo "build.sh: $*" >&2
    exit 1
}

# The toolchain has to be on the environment before make will find its compilers.
export PS2DEV="${PS2DEV:-/opt/toolchains/ps2dev}"
export PS2SDK="${PS2SDK:-$PS2DEV/ps2sdk}"
export GSKIT="${GSKIT:-$PS2DEV/gsKit}"
export PATH="$PATH:$PS2DEV/bin:$PS2SDK/bin:$PS2DEV/ee/bin:$PS2DEV/iop/bin:$PS2DEV/dvp/bin"

[ -d "$PS2SDK" ] || die "no ps2sdk at $PS2SDK -- export PS2DEV to point at your ps2dev install"
command -v mips64r5900el-ps2-elf-gcc > /dev/null \
    || die "the ee compiler is not on PATH; is $PS2DEV a complete ps2dev v2.0.0 install?"
for tool in make git python3; do
    command -v "$tool" > /dev/null || die "$tool is required"
done
python3 -c 'import yaml' 2> /dev/null || die "python3 needs PyYAML -- lang_compiler.py imports it"
command -v zip > /dev/null \
    || echo "build.sh: zip is not installed, so the release target's last step will fail" \
        "after the ELF is already complete -- the ELF is still collected"

LOG=build.log
: > "$LOG"
started=$SECONDS

if [ "$no_clean" -eq 0 ]; then
    echo "==> make clean"
    make clean 2>&1 | tee -a "$LOG"
    # make clean leaves these behind; a stale one would survive into the next build.
    find modules -name '*.notiopmod.elf' -delete
fi

echo "==> make release"
set +e
make release 2>&1 | tee -a "$LOG"
make_status=${PIPESTATUS[0]}
set -e

# The release target's last step packages a .ZIP, which can fail long after the ELF
# is finished, so what decides success here is the ELF existing -- not make's status.
elf=$(find . -maxdepth 1 -name 'WOPNPS2LD-*.ELF' -printf '%f\n' | head -n 1)
if [ -z "$elf" ]; then
    die "the build produced no WOPNPS2LD-*.ELF (make exited $make_status) -- see $LOG"
fi
if [ "$make_status" -ne 0 ]; then
    echo "build.sh: make exited $make_status, but $elf is complete." \
        "That is normally the .ZIP step -- check $LOG before trusting this build."
fi

sha=$(git rev-parse --short HEAD)
out="dist/wOPL-new-ui-$sha-$(date +%F).ELF"
mkdir -p dist
[ -e "$out" ] && echo "build.sh: replacing $out"
cp -f "$elf" "$out"

git diff --quiet \
    || echo "build.sh: the tree has uncommitted changes, so $sha does not fully describe this binary"

printf '\n%s\n  version %s\n  %s bytes, built in %ds\n' \
    "$out" "$(make -s woplversion | tr -d '\r' | tail -n 1)" \
    "$(stat -c %s "$out")" "$((SECONDS - started))"
echo "  dist/*.ELF is tracked: commit it only when the build is worth keeping, and add an entry to dist/BUILD-LOG.pt-BR.md"
