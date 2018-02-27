#!/bin/bash -e

#*******************************************************************************
# Check that we can access a dependencies directory
helper_check_dependencies_dir ()
{
    # first argument, default to /opt/midas if not set
    local DEPENDENCIES=${1:-"/opt/midas"}

    if [ ! -d "${DEPENDENCIES}/lib" ]; then
        >&2 echo "*** Error: Directory does not exist: ${DEPENDENCIES}/lib"
        >&2 echo "*** Set DEPENDENCIES=..."
        exit 1
    fi
}

#*******************************************************************************
# Check that we can access a frameworks directory
helper_check_frameworks_dir ()
{
    # first argument, default to /opt/midas/Frameworks if not set
    local FRAMEWORKS=${1:-"/opt/midas/Frameworks"}

    if [ ! -d "${FRAMEWORKS}" ]; then
        >&2 echo "*** Error: Directory does not exist: ${FRAMEWORKS}"
        >&2 echo "*** Set FRAMEWORKS=..."
        exit 1
    fi
}

#*******************************************************************************
# Check that we can access a file
helper_check_file_exists ()
{
    local FILENAME=${1}
    if [ ! -f "${FILENAME}" ]; then
        >&2 echo "*** Error: The file '${FILENAME}' does not exist"
        exit 1
    fi
}

#*******************************************************************************
# Determine the dynamic library file ending based on operating system.
# Uses echo to "return" a string. Catch it with
#
#   libending=$(helper_dynamic_library_ending)
#
helper_dynamic_library_ending ()
{
    # The variable 'OSTYPE' is set by bash
    case ${OSTYPE} in
        linux*)
            echo "so" ;;
        darwin*)
            echo "dylib" ;;
        #win*)
        #    echo "dll" ;;
        *)
            >&2 echo "Error. Can not determine OS"
            exit 1
    esac
}

#*******************************************************************************
# measure the time it takes to build (part 1)
helper_time_measure_start ()
{
    t_start_global=$(date +"%s")
}

#*******************************************************************************
# measure the time it takes to build (part 2)
helper_time_measure_stop ()
{
    # fail gracefully if time_measure_start hasn't been called
    # before this function is called.
    local t_start_local=${t_start_global:-$(date +"%s")}

    local t_elapsed=$(($(date +"%s")-$t_start_local))

    echo "---------------------------------------------------------------------"
    printf "Finished OK. Total build time: %02i:%02i    [mm:ss]\n" $(($t_elapsed / 60)) $(($t_elapsed % 60))
    echo "---------------------------------------------------------------------"
}
