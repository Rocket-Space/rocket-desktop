cmake_minimum_required(VERSION 3.20)
project(Rocket VERSION 1.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 WaylandClient Svg DBus)
find_package(KF6WindowSystem REQUIRED)
find_package(PkgConfig REQUIRED)

# Only keep pkg_check_modules that are actually used in src/CMakeLists.txt
# wayland-client is used via Qt6::WaylandClient, so WAYLAND_CLIENT is redundant
# dbus-1 is used via Qt6::DBus, so DBUS is redundant
# libnm, bluez, libpipewire-0.3 are declared but never used in source
# wayland-protocols is not linked directly

set(ROCKET_BIN_DIR ${CMAKE_INSTALL_PREFIX}/bin)
set(ROCKET_SHARE_DIR ${CMAKE_INSTALL_PREFIX}/share/rocket-desktop)
set(ROCKET_SESSION_DIR ${CMAKE_INSTALL_PREFIX}/share/wayland-sessions)
set(ROCKET_SYSTEMD_DIR ${CMAKE_INSTALL_PREFIX}/lib/systemd/user)

add_subdirectory(src)

# Install config, systemd services, autostart, session, and resources
install(DIRECTORY config/default DESTINATION ${CMAKE_INSTALL_PREFIX}/share/rocket-desktop)
install(DIRECTORY config/systemd/user DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/systemd/user)
install(DIRECTORY autostart DESTINATION ${CMAKE_INSTALL_PREFIX}/share/rocket-desktop)
install(FILES session/rocket-desktop.desktop DESTINATION ${ROCKET_SESSION_DIR})
install(DIRECTORY resources/ DESTINATION ${ROCKET_SHARE_DIR})