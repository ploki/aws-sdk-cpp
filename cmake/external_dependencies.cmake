

# Zlib
if(PLATFORM_ANDROID AND ANDROID_BUILD_ZLIB)
    set(BUILD_ZLIB 1)
    message(STATUS "  Building Zlib as part of AWS SDK")
elseif(NOT PLATFORM_WINDOWS AND NOT PLATFORM_CUSTOM)
    include(FindZLIB)
    if(NOT ZLIB_FOUND)
        message(FATAL_ERROR "Could not find zlib")
    else()
        message(STATUS "  Zlib include directory: ${ZLIB_INCLUDE_DIRS}")
        message(STATUS "  Zlib library: ${ZLIB_LIBRARIES}")
    endif()
    include_directories(${ZLIB_INCLUDE_DIRS})
endif()

# Encryption control
set(ENABLE_BCRYPT_ENCRYPTION 0)
set(ENABLE_OPENSSL_ENCRYPTION 0)
set(ENABLE_COMMONCRYPTO_ENCRYPTION 0)
set(ENABLE_INJECTED_ENCRYPTION 0)
if(NOT NO_ENCRYPTION)
    if(PLATFORM_WINDOWS)
        set(ENABLE_BCRYPT_ENCRYPTION 1)
    elseif(PLATFORM_LINUX OR PLATFORM_ANDROID)
        set(ENABLE_OPENSSL_ENCRYPTION 1)
    elseif(PLATFORM_APPLE)
        set(ENABLE_COMMONCRYPTO_ENCRYPTION 1)
    else()
        message(FATAL_ERROR "No encryption available for target platform and injection not enabled (-DNO_ENCRYPTION=1)")
    endif()
else()
    set(ENABLE_INJECTED_ENCRYPTION 1)
endif()

if(ENABLE_BCRYPT_ENCRYPTION)
    add_definitions(-DENABLE_BCRYPT_ENCRYPTION)
    set(CRYPTO_LIBS Bcrypt)
    message(STATUS "Encryption: Bcrypt")
elseif(ENABLE_OPENSSL_ENCRYPTION)
    add_definitions(-DENABLE_OPENSSL_ENCRYPTION)
    message(STATUS "Encryption: Openssl")

    if(PLATFORM_ANDROID AND ANDROID_BUILD_OPENSSL)
        set(BUILD_OPENSSL 1)
        message(STATUS "  Building Openssl as part of AWS SDK")
    else()
        include(FindOpenSSL)
        if(NOT OPENSSL_FOUND)
            message(FATAL_ERROR "Could not find openssl")
        else()
            message(STATUS "  Openssl include directory: ${OPENSSL_INCLUDE_DIR}")
            message(STATUS "  Openssl library: ${OPENSSL_LIBRARIES}")
        endif()

        include_directories(${OPENSSL_INCLUDE_DIR})
    endif()
    set(CRYPTO_LIBS ${OPENSSL_LIBRARIES} ${ZLIB_LIBRARIES})
elseif(ENABLE_COMMONCRYPTO_ENCRYPTION)
    add_definitions(-DENABLE_COMMONCRYPTO_ENCRYPTION)
    message(STATUS "Encryption: CommonCrypto")
elseif(ENABLE_INJECTED_ENCRYPTION)
    add_definitions(-DENABLE_INJECTED_ENCRYPTION)
    message(STATUS "Encryption: None")
    message(STATUS "You will need to inject an encryption implementation before making any http requests!")
endif()

# Http client control
set(ENABLE_CURL_CLIENT 0)
set(ENABLE_WINDOWS_CLIENT 0)
if(NOT NO_HTTP_CLIENT)
    if(PLATFORM_WINDOWS)
        if(FORCE_CURL)
            set(ENABLE_CURL_CLIENT 1)
        else()
            set(ENABLE_WINDOWS_CLIENT 1)
        endif()
    elseif(PLATFORM_LINUX OR PLATFORM_APPLE OR PLATFORM_ANDROID)
        set(ENABLE_CURL_CLIENT 1)
    endif()

    if(ENABLE_CURL_CLIENT)
        add_definitions(-DENABLE_CURL_CLIENT)
        message(STATUS "Http client: Curl")

        if(PLATFORM_ANDROID AND ANDROID_BUILD_CURL)
            set(BUILD_CURL 1)
            message(STATUS "  Building Openssl as part of AWS SDK")
        else()
            include(FindCURL)
            if(NOT CURL_FOUND)
                message(FATAL_ERROR "Could not find curl")
            else()
                message(STATUS "  Curl include directory: ${CURL_INCLUDE_DIRS}")
                message(STATUS "  Curl library: ${CURL_LIBRARIES}")
            endif()

            include_directories(${CURL_INCLUDE_DIRS})
        endif()

        if(TEST_CERT_PATH)
            message(STATUS "Setting curl cert path to ${TEST_CERT_PATH}")
            add_definitions(-DTEST_CERT_PATH="\"${TEST_CERT_PATH}\"")
        endif()

        set(CLIENT_LIBS ${CURL_LIBRARIES})
    elseif(ENABLE_WINDOWS_CLIENT)
        add_definitions(-DENABLE_WINDOWS_CLIENT)
        set(CLIENT_LIBS Wininet winhttp)

        message(STATUS "Http client: WinHttp")
    else()
        message(FATAL_ERROR "No http client available for target platform and client injection not enabled (-DNO_HTTP_CLIENT=ON)")
    endif()
else()
    message(STATUS "You will need to inject an http client implementation before making any http requests!")
endif()

# UUID headers
if(NOT PLATFORM_WINDOWS AND NOT PLATFORM_ANDROID AND NOT PLATFORM_CUSTOM)
    message(STATUS "Finding uuid")

    find_path(UUID_INCLUDE_DIR uuid/uuid.h)
    if(NOT PLATFORM_APPLE)
        find_library(UUID_LIBRARIES uuid)
    endif()

    if("${UUID_INCLUDE_DIR}" STREQUAL "UUID_INCLUDE_DIR-NOTFOUND" OR "${UUID_LIBRARIES}" STREQUAL "UUID_LIBRARIES-NOTFOUND")
        message(FATAL_ERROR "Could not find uuid components")
    else()
        message(STATUS "  Uuid include directory: ${UUID_INCLUDE_DIR}")
        message(STATUS "  Uuid library: ${UUID_LIBRARIES}")
    endif()

    include_directories(${UUID_INCLUDE_DIR})
endif()

