set(ROCKET_RESOURCES
    resources.qrc
)

set(ROCKET_SOURCES
    main.cpp
    ${ROCKET_RESOURCES}
    core/dbus_service.cpp
    core/config_manager.cpp
    panel/panel_window.cpp
    panel/widgets/workspace_indicator.cpp
    panel/widgets/taskbar.cpp
    panel/widgets/system_tray.cpp
    panel/widgets/clock.cpp
    panel/widgets/status_area.cpp
    launcher/launcher_window.cpp
    launcher/app_database.cpp
    overview/overview_window.cpp
    notifications/daemon.cpp
    notifications/popup.cpp
    wallpaper/renderer.cpp
    settings/settings_window.cpp
    power/power_manager.cpp
    clipboard/manager.cpp
    clipboard/history_window.cpp
    screenshot/screenshot_tool.cpp
    common/wayland_helpers.cpp
)

set(ROCKET_HEADERS
    core/dbus_service.h
    core/config_manager.h
    panel/panel_window.h
    panel/widgets/workspace_indicator.h
    panel/widgets/taskbar.h
    panel/widgets/system_tray.h
    panel/widgets/clock.h
    panel/widgets/status_area.h
    launcher/launcher_window.h
    launcher/app_database.h
    overview/overview_window.h
    notifications/daemon.h
    notifications/popup.h
    wallpaper/renderer.h
    settings/settings_window.h
    power/power_manager.h
    clipboard/manager.h
    clipboard/history_window.h
    screenshot/screenshot_tool.h
    common/wayland_helpers.h
    common/dbus_paths.h
)

set(ROCKET_QML
    ../qml/panel/Panel.qml
    ../qml/launcher/Launcher.qml
    ../qml/overview/Overview.qml
    ../qml/notifications/NotificationPopup.qml
    ../qml/settings/SettingsWindow.qml
    ../qml/clipboard/ClipboardHistory.qml
    ../qml/common/Theme.qml
)

add_executable(rocket-session-bin ${ROCKET_SOURCES} ${ROCKET_HEADERS})

target_include_directories(rocket-session-bin PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/common
    ${CMAKE_CURRENT_SOURCE_DIR}/core
    ${CMAKE_CURRENT_SOURCE_DIR}/panel
    ${CMAKE_CURRENT_SOURCE_DIR}/panel/widgets
    ${CMAKE_CURRENT_SOURCE_DIR}/launcher
    ${CMAKE_CURRENT_SOURCE_DIR}/overview
    ${CMAKE_CURRENT_SOURCE_DIR}/notifications
    ${CMAKE_CURRENT_SOURCE_DIR}/wallpaper
    ${CMAKE_CURRENT_SOURCE_DIR}/settings
    ${CMAKE_CURRENT_SOURCE_DIR}/power
    ${CMAKE_CURRENT_SOURCE_DIR}/clipboard
    ${CMAKE_CURRENT_SOURCE_DIR}/screenshot
    ${Qt6Gui_PRIVATE_INCLUDE_DIRS}
)

target_link_libraries(rocket-session-bin PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::WaylandClient
    Qt6::Svg
    Qt6::DBus
    KF6::WindowSystem
    ${WAYLAND_CLIENT_LIBRARIES}
    ${DBUS_LIBRARIES}
)

target_include_directories(rocket-session-bin PRIVATE
    ${WAYLAND_CLIENT_INCLUDE_DIRS}
    ${DBUS_INCLUDE_DIRS}
)

install(TARGETS rocket-session-bin RUNTIME DESTINATION ${ROCKET_BIN_DIR})
