#!/usr/bin/env bash
# build.sh
set -euo pipefail

readonly ROM_SIZE=$((0x1000))
readonly SOURCE_NAME="wow_disassembly.asm"
readonly ZIP_NAME="wow.zip"
readonly GERMAN_ZIP_NAME="wowg.zip"
readonly KLINGON_ZIP_NAME="wowk.zip"
readonly REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SOURCE_DIR="$REPO_ROOT/src"
readonly BUILD_DIR="$SOURCE_DIR/zout"
readonly ROMS_DIR="$REPO_ROOT/roms"
readonly SOURCE_FILE="$SOURCE_DIR/$SOURCE_NAME"
readonly SOURCE_STEM="${SOURCE_NAME%.asm}"
readonly CIM_FILE="$BUILD_DIR/$SOURCE_STEM.cim"
readonly LST_FILE="$BUILD_DIR/$SOURCE_STEM.lst"
readonly ZIP_FILE="$ROMS_DIR/$ZIP_NAME"
readonly GERMAN_ZIP_FILE="$ROMS_DIR/$GERMAN_ZIP_NAME"
readonly KLINGON_ZIP_FILE="$ROMS_DIR/$KLINGON_ZIP_NAME"
readonly SC01_FILE="$ROMS_DIR/sc01.bin"

# Optional language ROM paths
readonly GERMAN_SOURCE="$SOURCE_DIR/german/GERMAN_X11.asm"
readonly GERMAN_OUT_FILE="$ROMS_DIR/german.x11"
readonly KLINGON_SOURCE="$SOURCE_DIR/klingon/KLINGON_X11.asm"
readonly KLINGON_OUT_FILE="$ROMS_DIR/klingon.x11"
readonly KLINGON_RENAME_SCRIPT="$SOURCE_DIR/klingon/renameK.sh"
readonly KLINGON_MAME_ZIP_FILE="$GERMAN_ZIP_FILE"

readonly -a ROM_NAMES=(
    "wow.x1"
    "wow.x2"
    "wow.x3"
    "wow.x4"
    "wow.x5"
    "wow.x6"
    "wow.x7"
)
readonly -a ROM_ADDRESSES=(
    0x0000
    0x1000
    0x2000
    0x3000
    0x8000
    0x9000
    0xA000
)

# Global configuration variable controlled by arguments
BUILD_GERMAN=false
BUILD_KLINGON=false

log() {
    printf '%s\n' "$*"
}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

resolve_zmac() {
    local candidate
    if [[ -n "${ZMAC:-}" ]]; then
        if [[ "$ZMAC" == */* ]]; then
            [[ -x "$ZMAC" ]] || fail "ZMAC is not executable: $ZMAC"
            printf '%s\n' "$ZMAC"
        else
            candidate="$(command -v "$ZMAC" 2>/dev/null)" || fail "ZMAC command not found: $ZMAC"
            printf '%s\n' "$candidate"
        fi
        return
    fi

    candidate="$REPO_ROOT/tools/zmac"
    if [[ -x "$candidate" ]]; then
        printf '%s\n' "$candidate"
        return
    fi

    candidate="$(command -v zmac 2>/dev/null)" || fail "zmac was not found. Install it in PATH, place it at tools/zmac, or set ZMAC=/path/to/zmac."
    printf '%s\n' "$candidate"
}

prepare_output_directories() {
    local rom_name
    rm -rf -- "$BUILD_DIR"
    mkdir -p -- "$BUILD_DIR" "$ROMS_DIR"
    for rom_name in "${ROM_NAMES[@]}"; do
        rm -f -- "$ROMS_DIR/$rom_name"
    done
    rm -f -- "$GERMAN_OUT_FILE"
    [[ "$BUILD_KLINGON" == true ]] && rm -f -- "$KLINGON_OUT_FILE"
    if [[ "$BUILD_KLINGON" == true ]]; then
        rm -f -- "$KLINGON_ZIP_FILE" "$KLINGON_MAME_ZIP_FILE"
    elif [[ "$BUILD_GERMAN" == true ]]; then
        rm -f -- "$GERMAN_ZIP_FILE"
    else
        rm -f -- "$ZIP_FILE"
    fi
}

assemble_source() {
    log "[2/4] Assembling $SOURCE_NAME"
    log "      zmac: $ZMAC_BIN"

    # Detect if we are using an old v1.x version or the newer v2022 fork
    if "$ZMAC_BIN" --version 2>&1 | grep -q '1\.3'; then
        log "      Detected zmac v1.3 compatibility mode"
        (
            cd -- "$REPO_ROOT"
            "$ZMAC_BIN" -o "$CIM_FILE" -x "$LST_FILE" "$SOURCE_FILE"
        ) || fail "zmac v1.3 failed. Review the assembler output above."
    else
        log "      Detected modern zmac mode"
        (
            cd -- "$REPO_ROOT"
            "$ZMAC_BIN" -I "$REPO_ROOT" -I "$SOURCE_DIR" --od "$BUILD_DIR" --oo cim,lst "$SOURCE_FILE"
        ) || fail "zmac failed. Review the assembler output above."
    fi

    [[ -s "$CIM_FILE" ]] || fail "zmac did not create $CIM_FILE"
    [[ -s "$LST_FILE" ]] || fail "zmac did not create $LST_FILE"
    log "     image: $CIM_FILE ($(stat -c '%s bytes' "$CIM_FILE"))"
    log "   listing: $LST_FILE"
}

assemble_german() {
    [[ -f "$GERMAN_SOURCE" ]] || fail "German source file not found: $GERMAN_SOURCE"
    log "[2.5/4] Assembling Optional German ROM: GERMAN_X11.asm"
    
    local german_tmp_cim="$BUILD_DIR/GERMAN_X11.cim"
    
    if "$ZMAC_BIN" --version 2>&1 | grep -q '1\.3'; then
        log "      Detected zmac v1.3 compatibility mode for German ROM"
        (
            cd -- "$REPO_ROOT"
            "$ZMAC_BIN" -o "$german_tmp_cim" -x "$BUILD_DIR/GERMAN_X11.lst" "$GERMAN_SOURCE"
        ) || fail "zmac v1.3 failed on German ROM."
    else
        log "      Detected modern zmac mode for German ROM"
        (
            cd -- "$REPO_ROOT"
            "$ZMAC_BIN" -I "$REPO_ROOT" -I "$SOURCE_DIR" -I "$SOURCE_DIR/german" --od "$BUILD_DIR" --oo cim,lst "$GERMAN_SOURCE"
        ) || fail "zmac failed on German ROM."
    fi

    [[ -s "$german_tmp_cim" ]] || fail "zmac did not create $german_tmp_cim"
    cp -- "$german_tmp_cim" "$GERMAN_OUT_FILE"
    log "    german: $GERMAN_OUT_FILE ($(stat -c '%s bytes' "$GERMAN_OUT_FILE"))"
}


assemble_klingon() {
    [[ -f "$KLINGON_SOURCE" ]] || fail "Klingon source file not found: $KLINGON_SOURCE"
    log "[2.5/4] Assembling Optional Klingon ROM: KLINGON_X11.asm"

    local klingon_tmp_cim="$BUILD_DIR/KLINGON_X11.cim"

    if "$ZMAC_BIN" --version 2>&1 | grep -q '1\.3'; then
        log "      Detected zmac v1.3 compatibility mode for Klingon ROM"
        (
            cd -- "$REPO_ROOT"
            "$ZMAC_BIN" -o "$klingon_tmp_cim" -x "$BUILD_DIR/KLINGON_X11.lst" "$KLINGON_SOURCE"
        ) || fail "zmac v1.3 failed on Klingon ROM."
    else
        log "      Detected modern zmac mode for Klingon ROM"
        (
            cd -- "$REPO_ROOT"
            "$ZMAC_BIN" -I "$REPO_ROOT" -I "$SOURCE_DIR" -I "$SOURCE_DIR/klingon" --od "$BUILD_DIR" --oo cim,lst "$KLINGON_SOURCE"
        ) || fail "zmac failed on Klingon ROM."
    fi

    [[ -s "$klingon_tmp_cim" ]] || fail "zmac did not create $klingon_tmp_cim"
    cp -- "$klingon_tmp_cim" "$KLINGON_OUT_FILE"
    log "   klingon: $KLINGON_OUT_FILE ($(stat -c '%s bytes' "$KLINGON_OUT_FILE"))"
}

slice_roms() {
    local cim_size local index local rom_name local start_address local end_address local output_file local output_size
    cim_size="$(stat -c '%s' "$CIM_FILE")"
    (( cim_size > ROM_ADDRESSES[${#ROM_ADDRESSES[@]} - 1] )) || fail "Assembled image is too short for the ROM map: $cim_size bytes"

    log "[3/4] Splitting the CPU image into 4 KB ROMs"
    log "      The video-memory gap at \$4000-\$7FFF is not packaged."

    for index in "${!ROM_NAMES[@]}"; do
        rom_name="${ROM_NAMES[$index]}"
        start_address="${ROM_ADDRESSES[$index]}"
        end_address=$((start_address + ROM_SIZE - 1))
        output_file="$ROMS_DIR/$rom_name"

        dd if=/dev/zero bs="$ROM_SIZE" count=1 status=none | tr '\000' '\377' > "$output_file"
        dd if="$CIM_FILE" of="$output_file" bs="$ROM_SIZE" skip="$((start_address / ROM_SIZE))" count=1 conv=notrunc status=none

        output_size="$(stat -c '%s' "$output_file")"
        (( output_size == ROM_SIZE )) || fail "$rom_name is $output_size bytes; expected $ROM_SIZE"
        printf '  %-12s CPU $%04X-$%04X %5d bytes\n' "$rom_name" "$start_address" "$end_address" "$output_size"
    done
}

create_zip() {
    local rom_name
    local target_zip="$ZIP_FILE"
    local -a zip_inputs=()

    if [[ "$BUILD_GERMAN" == true ]]; then
        target_zip="$GERMAN_ZIP_FILE"
    elif [[ "$BUILD_KLINGON" == true ]]; then
        target_zip="$KLINGON_ZIP_FILE"
    fi

    for rom_name in "${ROM_NAMES[@]}"; do
        zip_inputs+=("$ROMS_DIR/$rom_name")
    done

    if [[ -f "$SC01_FILE" ]]; then
        zip_inputs+=("$SC01_FILE")
        log "      Including optional speech ROM: $SC01_FILE"
    else
        log "      Optional speech ROM not found; sc01.bin will not be included."
    fi

    if [[ "$BUILD_GERMAN" == true ]]; then
        [[ -f "$GERMAN_OUT_FILE" ]] || fail "German ROM build was requested but file is missing: $GERMAN_OUT_FILE"
        zip_inputs+=("$GERMAN_OUT_FILE")
        log "      Including optional German language ROM: $GERMAN_OUT_FILE"
    fi

    if [[ "$BUILD_KLINGON" == true ]]; then
        [[ -f "$KLINGON_OUT_FILE" ]] || fail "Klingon ROM build was requested but file is missing: $KLINGON_OUT_FILE"
        zip_inputs+=("$KLINGON_OUT_FILE")
        log "      Including optional Klingon language ROM: $KLINGON_OUT_FILE"
    fi

    (
        cd -- "$ROMS_DIR"
        zip -q -j -X "$target_zip" "${zip_inputs[@]}"
    ) || fail "Could not create $target_zip"

    [[ -s "$target_zip" ]] || fail "ZIP archive was not created: $target_zip"
    log "   archive: $target_zip ($(stat -c '%s bytes' "$target_zip"))"
}


create_klingon_mame_zip() {
    [[ -f "$KLINGON_RENAME_SCRIPT" ]] || fail "Klingon rename script not found: $KLINGON_RENAME_SCRIPT"

    log "[4.5/4] Creating MAME-compatible Klingon archive"
    (
        cd -- "$(dirname -- "$KLINGON_RENAME_SCRIPT")"
        bash "./$(basename -- "$KLINGON_RENAME_SCRIPT")"
    ) || fail "Could not create MAME-compatible Klingon archive"

    [[ -s "$KLINGON_MAME_ZIP_FILE" ]] || fail "MAME-compatible archive was not created: $KLINGON_MAME_ZIP_FILE"
    log "   archive: $KLINGON_MAME_ZIP_FILE"
    log "      X11: klingon.x11 packaged as german.x11 for the MAME wowg driver"
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -g|--german)
                BUILD_GERMAN=true
                shift
                ;;
            -k|-klingon|--klingon)
                BUILD_KLINGON=true
                shift
                ;;
            -h|--help)
                log "Usage: $0 [options]"
                log "Options:"
                log "  -g, --german              Build the MAME-ready German archive wowg.zip"
                log "  -k, -klingon, --klingon   Build wowk.zip and the MAME-ready wowg.zip alias"
                log "  -h, --help                Display this help message"
                exit 0
                ;;
            *)
                fail "Unknown argument: $1. Use --help for usage details."
                ;;
        esac
    done
}

main() {
    local ZMAC_BIN
    parse_arguments "$@"

    if [[ "$BUILD_GERMAN" == true && "$BUILD_KLINGON" == true ]]; then
        fail "Select either German or Klingon, not both."
    fi

    [[ -f "$SOURCE_FILE" ]] || fail "Source file not found: $SOURCE_FILE"
    require_command dd
    require_command stat
    require_command tr
    require_command zip

    ZMAC_BIN="$(resolve_zmac)"

    log "ROM build"
    log "    source: $SOURCE_FILE"
    log "    output: $ROMS_DIR"
    log

    log "[1/4] Preparing clean build and ROM output"
    prepare_output_directories

    assemble_source

    if [[ "$BUILD_GERMAN" == true ]]; then
        assemble_german
    elif [[ "$BUILD_KLINGON" == true ]]; then
        assemble_klingon
    fi

    slice_roms

    if [[ "$BUILD_KLINGON" == true ]]; then
        log "[4/4] Creating $KLINGON_ZIP_NAME"
    elif [[ "$BUILD_GERMAN" == true ]]; then
        log "[4/4] Creating $GERMAN_ZIP_NAME"
    else
        log "[4/4] Creating $ZIP_NAME"
    fi
    create_zip

    if [[ "$BUILD_KLINGON" == true ]]; then
        create_klingon_mame_zip
    fi
    log

    log "Build complete."
    log "  ROM files: $ROMS_DIR/wow.x{1..7}"
    [[ "$BUILD_GERMAN" == true ]] && log " German ROM: $GERMAN_OUT_FILE"
    [[ "$BUILD_KLINGON" == true ]] && log "Klingon ROM: $KLINGON_OUT_FILE"
    if [[ "$BUILD_KLINGON" == true ]]; then
        log "Klingon ZIP: $KLINGON_ZIP_FILE"
        log "   MAME ZIP: $KLINGON_MAME_ZIP_FILE"
    elif [[ "$BUILD_GERMAN" == true ]]; then
        log "  MAME ZIP: $GERMAN_ZIP_FILE"
    else
        log "  MAME ZIP: $ZIP_FILE"
    fi
}

main "$@"
