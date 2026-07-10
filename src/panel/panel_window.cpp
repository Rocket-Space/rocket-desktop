#include "panel_window.h"

namespace Rocket {

PanelWindow::PanelWindow(QObject* parent) : QObject(parent) {}
PanelWindow::~PanelWindow() {}

int PanelWindow::width() const { return m_width; }
int PanelWindow::height() const { return m_height; }
int PanelWindow::x() const { return m_x; }
int PanelWindow::y() const { return m_y; }
QString PanelWindow::position() const { return m_position; }
bool PanelWindow::isVisible() const { return m_visible; }
float PanelWindow::opacity() const { return m_opacity; }

void PanelWindow::setWidth(int w) { if (m_width != w) { m_width = w; emit widthChanged(); } }
void PanelWindow::setHeight(int h) { if (m_height != h) { m_height = h; emit heightChanged(); } }
void PanelWindow::setX(int x) { if (m_x != x) { m_x = x; emit xChanged(); } }
void PanelWindow::setY(int y) { if (m_y != y) { m_y = y; emit yChanged(); } }
void PanelWindow::setPosition(const QString& pos) { if (m_position != pos) { m_position = pos; emit positionChanged(); } }
void PanelWindow::setVisible(bool v) { if (m_visible != v) { m_visible = v; emit visibleChanged(); } }
void PanelWindow::setOpacity(float o) { if (m_opacity != o) { m_opacity = o; emit opacityChanged(); } }

void PanelWindow::toggle() { setVisible(!m_visible); }
void PanelWindow::show() { setVisible(true); }
void PanelWindow::hide() { setVisible(false); }

}
