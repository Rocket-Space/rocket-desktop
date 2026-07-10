import QtQuick 2.15
import org.kde.kwin 3.0 as KWin

KWin.SceneEffect {
    id: root

    property real animationDuration: 300
    property real openDuration: 250
    property real closeDuration: 200

    KWin.WindowModel {
        id: windowModel
    }

    // Animate new windows: fade in + scale up
    component WindowOpenAnimation {
        id: openAnim

        property real progress: 0

        SequentialAnimation {
            running: true
            NumberAnimation {
                target: openAnim
                property: "progress"
                from: 0; to: 1
                duration: root.openDuration
                easing.type: Easing.OutCubic
            }
            ScriptAction {
                script: openAnim.window.setData(1, undefined) // mark animation done
            }
        }

        // Apply transform
        transform: [
            Scale {
                origin.x: openAnim.window ? openAnim.window.width / 2 : 0
                origin.y: openAnim ? openAnim.window.height / 2 : 0
                xScale: 0.92 + 0.08 * openAnim.progress
                yScale: 0.92 + 0.08 * openAnim.progress
            },
            Opacity {
                opacity: openAnim.progress
            }
        ]
    }

    // Shader for the effect
    shader: ShaderEffect {
        property variant texture: shaderSource
        property real opacity: 1.0

        vertexShader: "
            attribute highp vec4 vertices;
            attribute highp vec2 texCoord;
            varying highp vec2 uv;
            void main() {
                uv = texCoord;
                gl_Position = vertices;
            }
        "
        fragmentShader: "
            uniform sampler2D texture;
            uniform lowp float opacity;
            varying highp vec2 uv;
            void main() {
                gl_FragColor = texture2D(texture, uv) * opacity;
            }
        "
    }
}
