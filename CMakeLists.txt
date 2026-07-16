cmake_minimum_required(VERSION 3.20)
project(Rocket VERSION 1.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 WaylandClient Svg DBus)
find_package(KF6WindowSystem REQUIRED)
find_package(LayerShellQt REQUIRED)
find_package(PkgConfig REQUIRED)

add_subdirectory(src)

# Install config, systemd services, autostart, session, profile, and resources
# Use relative paths - CMake applies CMAKE_INSTALL_PREFIX automatically
install(DIRECTORY config/default/ DESTINATION share/rocket-desktop)
install(DIRECTORY config/profile.d/ DESTINATION etc/profile.d)
install(DIRECTORY autostart/ DESTINATION share/rocket-desktop/autostart)
install(FILES session/rocket-desktop.desktop DESTINATION share/wayland-sessions)
install(DIRECTORY wallpapers/ DESTINATION share/rocket-desktop)

# Startup is handled exclusively by SDDM autologin (configured in scripts/install.sh).
# No systemd autologin/session services are installed or enabled to avoid duplicate
# sessions competing for TTYs.