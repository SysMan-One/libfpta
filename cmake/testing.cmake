find_package(GTest)
include(ExternalProject)

if(NOT GTEST_FOUND)
    message(STATUS "Lookup gtest sources...")
    find_path(GTEST_CMAKE_PROJ CMakeLists.txt /usr/src/gtest /usr/local/gtest /usr/local/src/gtest)
    message(STATUS "GTEST_CMAKE_PROJ = ${GTEST_CMAKE_PROJ}")
    if(GTEST_CMAKE_PROJ)
        externalproject_add(GTEST PREFIX "${CMAKE_BINARY_DIR}/gtest" SOURCE_DIR "${GTEST_CMAKE_PROJ}" INSTALL_COMMAND "")
        set(GTEST_BUILTIN TRUE)
        set(GTEST_FOUND "${GTEST_CMAKE_PROJ}")

        get_filename_component(GTEST_DIR "${GTEST_CMAKE_PROJ}" PATH)
        if(NOT GTEST_INCLUDE_DIRS)
            find_path(GTEST_INCLUDE_DIRS gtest/gtest.h "${GTEST_DIR}")
        endif()

        set(GTEST_LIBDIR "${CMAKE_BINARY_DIR}/gtest/src/GTEST-build")
        set(GTEST_LIBRARIES "${GTEST_LIBDIR}/libgtest.a")
        set(GTEST_MAIN_LIBRARIES "${GTEST_LIBDIR}/libgtest_main.a")
        set(GTEST_BOTH_LIBRARIES ${GTEST_LIBRARIES} ${GTEST_MAIN_LIBRARIES})
    endif()
endif()

if(GTEST_FOUND)
    include (CTest)
    enable_testing ()
    set(UT_INCLUDE_DIRECTORIES ${GTEST_INCLUDE_DIRS})
    set(UT_LIBRARIES ${GTEST_BOTH_LIBRARIES} ${CMAKE_THREAD_LIBS_INIT})
else()
    set(UT_INCLUDE_DIRECTORIES "")
    set(UT_LIBRARIES "")
endif()

function(add_gtest name)
    set(options DISABLED)
    set(oneValueArgs TIMEOUT PREFIX)
    set(multiValueArgs SOURCE LIBRARY INCLUDE_DIRECTORY DEPEND)
    cmake_parse_arguments(params "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(params_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown keywords given to add_gtest(): \"${params_UNPARSED_ARGUMENTS}\".")
    endif()

    if(GTEST_FOUND)
        macro(oops)
            message(FATAL_ERROR "add_gtest(): Opps, " ${ARGV})
        endmacro()

        if(NOT params_SOURCE)
            set(params_SOURCE ${name}.cpp)
        endif()

        set(target "${params_PREFIX}${name}")
        add_executable(${target} ${params_SOURCE})

        if(GTEST_BUILTIN)
            add_dependencies(${target} GTEST)
        endif()

        if(params_DEPEND)
            add_dependencies(${target} ${params_DEPEND})
        endif()

        target_link_libraries(${target} ${UT_LIBRARIES})

        if(params_LIBRARY)
            target_link_libraries(${target} ${params_LIBRARY})
        endif()

        if(params_INCLUDE_DIRECTORY)
            set_target_properties(${target} PROPERTIES INCLUDE_DIRECTORIES ${params_INCLUDE_DIRECTORY})
        endif()

        if(NOT params_DISABLED)
            add_test(${name} ${target})
            if(params_TIMEOUT)
                set_tests_properties(${name} PROPERTIES TIMEOUT ${params_TIMEOUT})
            endif()
        endif()
    endif()
endfunction(add_gtest)

function(add_ut name)
    add_gtest(${name} PREFIX "ut_" ${ARGN})
endfunction(add_ut)

function(add_long_test name)
    add_gtest(${name} PREFIX "lt_" DISABLED ${ARGN})
endfunction(add_long_test)

function(add_perf_test name)
    add_gtest(${name} PREFIX "pt_" DISABLED ${ARGN})
endfunction(add_perf_test)
