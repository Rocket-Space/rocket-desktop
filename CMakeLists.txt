cmake_minimum_required(VERSION 3.20)
project(Rocket VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 WaylandClient Svg DBus)
find_package(KF6WindowSystem REQUIRED)
find_package(PkgConfig REQUIRED)

pkg_check_modules(WAYLAND_CLIENT wayland-client)
pkg_check_modules(WAYLAND_PROTOCOLS wayland-protocols)
pkg_check_modules(DBUS dbus-1)
pkg_check_modules(NM libnm)
pkg_check_modules(BLUEZ bluez)
pkg_check_modules(PIPEWIRE libpipewire-0.3)

set(ROCKET_BIN_DIR ${CMAKE_INSTALL_PREFIX}/bin)
set(ROCKET_SHARE_DIR ${CMAKE_INSTALL_PREFIX}/share/rocket-desktop)
set(ROCKET_SESSION_DIR ${CMAKE_INSTALL_PREFIX}/share/wayland-sessions)
set(ROCKET_SYSTEMD_DIR ${CMAKE_INSTALL_PREFIX}/lib/systemd/user)

add_subdirectory(src)

install(DIRECTORY config/default DESTINATION ${CMAKE_INSTALL_PREFIX}/share/rocket-desktop)
install(DIRECTORY resources/ DESTINATION ${ROCKET_SHARE_DIR})
