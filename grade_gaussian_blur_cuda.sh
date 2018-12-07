#!/bin/bash

set -o pipefail
#set -xv # debug

# Absolute path of this file
CWD=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

#
# Logging helpers
#
log() {
    echo -e "${*}"
}

info() {
    log "Info: ${*}"
}
warning() {
    log "Warning: ${*}"
}
error() {
    log "Error: ${*}"
}
die() {
    error "${*}"
    exit 1
}

#
# Scoring helpers
#
TOTAL=0
ANSWERS=()

add_answer() {
    log "Score: ${1}/1.0"
    ANSWERS+=("${1},")
}

inc_total() {
    let "TOTAL++"
}

# Returns a specific line in a multi-line string
select_line() {
    # 1: string
    # 2: line to select
    echo "$(echo "${1}" | sed "${2}q;d")"
}

fail() {
    # 1: got
    # 2: expected
    log "Fail: got '${1}' but expected '${2}'"
}

pass() {
    # got
    log "Pass: ${1}"
}

compare_output_lines() {
    # 1: output
    # 2: expected
    # 3: point step
    declare -a output_lines=("${!1}")
    declare -a expect_lines=("${!2}")
    local pts_step="${3}"

    for i in ${!output_lines[*]}; do
        if [[ "${output_lines[${i}]}" == "${expect_lines[${i}]}" ]]; then
            pass "${output_lines[${i}]}"
            sub=$(bc<<<"${sub}+${pts_step}")
        else
            fail "${output_lines[${i}]}" "${expect_lines[${i}]}" ]]
        fi
    done
}

#
# Generic function for running tests
#
EXEC="gaussian_blur_cuda"
run_test() {
	#1: executable name
	local exec="${1}"
	shift
    #1: cli arguments
    local args=("${@}")

    # These are global variables after the test has run so clear them out now
    unset STDOUT STDERR RET

    # Create temp files for getting stdout and stderr
    local outfile=$(mktemp)
    local errfile=$(mktemp)

    # Encapsulates commands with `timeout` in case the process hangs indefinitely
    timeout 10 bash -c "${exec} ${args[*]}" >${outfile} 2>${errfile}

    # Get the return status, stdout and stderr of the test case
    RET="${?}"
    STDOUT=$(cat "${outfile}")
    STDERR=$(cat "${errfile}")

    # Deal with the possible timeout errors
    [[ ${RET} -eq 127 ]] && die "Something is wrong (the executable might not exist)"
    [[ ${RET} -eq 124 ]] && warning "Command timed out..."

    # Clean up temp files
    rm -f "${outfile}"
    rm -f "${errfile}"
}

#
# Test cases
#
TEST_CASES=()

## Default reference image folder
REF_IMG_DIR=${IMGDIR:-"/home/cs158/public/p4"}

## Error management usage (no args)
TEST_CASES+=("err_no_arg")
err_no_arg() {
    log "\n--- Running ${FUNCNAME} ---"
    inc_total
    sub=0

    run_test "./gaussian_blur_cuda"

    local line_array=()
    line_array+=("$(select_line "${STDERR}" "1")")
    line_array+=("Return code: '${RET}'")
    local corr_array=()
    corr_array+=("Usage: ./gaussian_blur_cuda <input_file> <output_file> <sigma>")
    corr_array+=("Return code: '1'")
    compare_output_lines line_array[@] corr_array[@] "0.5"
    add_answer "${sub}"
}

## Error management file doesnt exist
TEST_CASES+=("err_no_file")
err_no_file() {
    log "\n--- Running ${FUNCNAME} ---"
    inc_total
    sub=0

    run_test "./gaussian_blur_cuda" doesntexist doesntexist_1 1

    local line_array=()
    line_array+=("$(select_line "${STDERR}" "1")")
    line_array+=("Return code: '${RET}'")
    local corr_array=()
    corr_array+=("Error: cannot open file doesntexist")
    corr_array+=("Return code: '1'")
    compare_output_lines line_array[@] corr_array[@] "0.5"
    add_answer "${sub}"
}

## Error management invalid pgm info (P5)
TEST_CASES+=("err_inval_pgm_p5")
err_inval_pgm_p5() {
    log "\n--- Running ${FUNCNAME} ---"
    inc_total
    sub=0

    run_test "./gaussian_blur_cuda" "<(echo -e \"not PGM\")" toto_1 1

    local line_array=()
    line_array+=("$(select_line "${STDERR}" "1")")
    line_array+=("Return code: '${RET}'")
    local corr_array=()
    corr_array+=("Error: invalid PGM information")
    corr_array+=("Return code: '1'")
    compare_output_lines line_array[@] corr_array[@] "0.5"
    add_answer "${sub}"
}

## Error management invalid pgm info (dimensions)
TEST_CASES+=("err_inval_pgm_dim")
err_inval_pgm_dim() {
    log "\n--- Running ${FUNCNAME} ---"
    inc_total
    sub=0

    run_test "./gaussian_blur_cuda" "<(echo -e \"P5\n2\n\")" toto_1 1

    local line_array=()
    line_array+=("$(select_line "${STDERR}" "1")")
    line_array+=("Return code: '${RET}'")
    local corr_array=()
    corr_array+=("Error: invalid PGM information")
    corr_array+=("Return code: '1'")
    compare_output_lines line_array[@] corr_array[@] "0.5"
    add_answer "${sub}"
}

## Error management invalid pgm pixels
TEST_CASES+=("err_inval_pgm_pix")
err_inval_pgm_pix() {
    log "\n--- Running ${FUNCNAME} ---"
    inc_total
    sub=0

    run_test "./gaussian_blur_cuda" "<(echo -e \"P5\n2 2\n255\n\")" toto_1 1

    local line_array=()
    line_array+=("$(select_line "${STDERR}" "1")")
    line_array+=("Return code: '${RET}'")
    local corr_array=()
    corr_array+=("Error: invalid PGM pixels")
    corr_array+=("Return code: '1'")
    compare_output_lines line_array[@] corr_array[@] "0.5"
    add_answer "${sub}"
}

## Error management invalid sigma (too big)
TEST_CASES+=("err_inval_sigma_big")
err_inval_sigma_big() {
    log "\n--- Running ${FUNCNAME} ---"
    inc_total
    sub=0

    run_test "./gaussian_blur_cuda" "${REF_IMG_DIR}/city_256.pgm" city_256_45.pgm 45

    local line_array=()
    line_array+=("$(select_line "${STDERR}" "1")")
    line_array+=("Return code: '${RET}'")
    local corr_array=()
    corr_array+=("Error: sigma value too big for image size")
    corr_array+=("Return code: '1'")
    compare_output_lines line_array[@] corr_array[@] "0.5"
    add_answer "${sub}"
}

## Error management invalid sigma (toto)
TEST_CASES+=("err_inval_sigma_toto")
err_inval_sigma_toto() {
    log "\n--- Running ${FUNCNAME} ---"
    inc_total
    sub=0

    run_test "./gaussian_blur_cuda" "${REF_IMG_DIR}/city_256.pgm" city_256_45.pgm toto

    local line_array=()
    line_array+=("$(select_line "${STDERR}" "1")")
    line_array+=("Return code: '${RET}'")
    local corr_array=()
    corr_array+=("Error: invalid sigma value")
    corr_array+=("Return code: '1'")
    compare_output_lines line_array[@] corr_array[@] "0.5"
    add_answer "${sub}"
}

## Validation cuda (city_256 sigma of 2.3)
TEST_CASES+=("val_city_256_23")
val_city_256_23() {
    log "\n--- Running ${FUNCNAME} ---"
    inc_total
    sub=0

    run_test "./gaussian_blur_cuda" \
        "${REF_IMG_DIR}/city_256.pgm" city_256_2-3.pgm 2.3
    run_test compare -channel gray -fuzz 1% -metric AE \
        "${REF_IMG_DIR}/city_256_2-3.pgm" city_256_2-3.pgm diff.pgm

    local line_array=()
    line_array+=("$(select_line "${STDERR}" "1")")
    local corr_array=()
    corr_array+=("0")
    compare_output_lines line_array[@] corr_array[@] "1"
    add_answer "${sub}"
}

## Validation cuda (lenna_512 sigma of 8.6)
TEST_CASES+=("val_lenna_512_86")
val_lenna_512_86() {
    log "\n--- Running ${FUNCNAME} ---"
    inc_total
    sub=0

    run_test "./gaussian_blur_cuda" \
        "${REF_IMG_DIR}/lenna_512.pgm" lenna_512_8-6.pgm 8.6
    run_test compare -channel gray -fuzz 1% -metric AE \
        "${REF_IMG_DIR}/lenna_512_8-6.pgm" lenna_512_8-6.pgm diff.pgm

    local line_array=()
    line_array+=("$(select_line "${STDERR}" "1")")
    local corr_array=()
    corr_array+=("0")
    compare_output_lines line_array[@] corr_array[@] "1"
    add_answer "${sub}"
}

## Validation cuda (gentilhomme_1024 sigma of 4.2)
TEST_CASES+=("val_gentilhomme_1024_42")
val_gentilhomme_1024_42() {
    log "\n--- Running ${FUNCNAME} ---"
    inc_total
    sub=0

    run_test "./gaussian_blur_cuda" \
        "${REF_IMG_DIR}/gentilhomme_1024.pgm" gentilhomme_1024_4-2.pgm 4.2
    run_test compare -channel gray -fuzz 1% -metric AE \
        "${REF_IMG_DIR}/gentilhomme_1024_4-2.pgm" gentilhomme_1024_4-2.pgm diff.pgm

    local line_array=()
    line_array+=("$(select_line "${STDERR}" "1")")
    local corr_array=()
    corr_array+=("0")
    compare_output_lines line_array[@] corr_array[@] "1"
    add_answer "${sub}"
}

## Validation cuda (ucd_pavilion_15mp sigma of 1)
TEST_CASES+=("val_ucd_pavilion_15mp_1")
val_ucd_pavilion_15mp_1() {
    log "\n--- Running ${FUNCNAME} ---"
    inc_total
    sub=0

    run_test "./gaussian_blur_cuda" \
        "${REF_IMG_DIR}/ucd_pavilion_15mp.pgm" ucd_pavilion_15mp_1.pgm 1
    run_test compare -channel gray -fuzz 1% -metric AE \
        "${REF_IMG_DIR}/ucd_pavilion_15mp_1.pgm" ucd_pavilion_15mp_1.pgm diff.pgm

    local line_array=()
    line_array+=("$(select_line "${STDERR}" "1")")
    local corr_array=()
    corr_array+=("0")
    compare_output_lines line_array[@] corr_array[@] "1"
    add_answer "${sub}"
}

## Validation cuda (ucd_pavilion_15mp sigma of 5)
TEST_CASES+=("val_ucd_pavilion_15mp_5")
val_ucd_pavilion_15mp_5() {
    log "\n--- Running ${FUNCNAME} ---"
    inc_total
    sub=0

    run_test "./gaussian_blur_cuda" \
        "${REF_IMG_DIR}/ucd_pavilion_15mp.pgm" ucd_pavilion_15mp_5.pgm 5
    run_test compare -channel gray -fuzz 1% -metric AE \
        "${REF_IMG_DIR}/ucd_pavilion_15mp_5.pgm" ucd_pavilion_15mp_5.pgm diff.pgm

    local line_array=()
    line_array+=("$(select_line "${STDERR}" "1")")
    local corr_array=()
    corr_array+=("0")
    compare_output_lines line_array[@] corr_array[@] "1"
    add_answer "${sub}"
}


#
# Main functions
#
TDIR=test_dir

clean_tdir() {
    cd ..
    rm -rf "${TDIR}"
}

make_exec() {
    # Make sure there no executable
    rm -f "${EXEC}"

    # Compile
    make > /dev/null 2>&1 ||
        die "Compilation failed"

    # Make sure that the shell executable was created
    if [[ ! -x "${EXEC}" ]]; then
        clean_tdir
        die "Can't find executable after compilation"
    fi
}

prep_tdir() {
    # Make a new testing directory
    rm -rf "${TDIR}"
    mkdir "${TDIR}" && cd "${TDIR}"

    cp "../${EXEC}" .
}

main_func() {
    # Run all the tests
    for t in "${TEST_CASES[@]}"; do
        ${t}
    done

    # Remove last comma from last answer entry
    ANSWERS[-1]=${ANSWERS[-1]%?}

    # Log the results
    log "\n\n--- Final results ---"
    log "${TOTAL} test cases were passed"
    log "${ANSWERS[*]}"
}

cd "${CWD}"
make_exec
prep_tdir
main_func
clean_tdir
