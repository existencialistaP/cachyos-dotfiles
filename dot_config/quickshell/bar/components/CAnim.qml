import QtQuick

// Mesmos tokens do Anim.qml, para propriedades de cor.
ColorAnimation {
    enum Type {
        StandardSmall,
        Standard,
        StandardLarge,
        StandardExtraLarge,
        EmphasizedSmall,
        Emphasized,
        EmphasizedLarge,
        EmphasizedExtraLarge,
        FastSpatial,
        DefaultSpatial,
        SlowSpatial,
        FastEffects,
        DefaultEffects,
        SlowEffects
    }

    property int type: CAnim.DefaultEffects

    duration: {
        switch (type) {
        case CAnim.StandardSmall: return 200
        case CAnim.Standard: return 400
        case CAnim.StandardLarge: return 600
        case CAnim.StandardExtraLarge: return 1000
        case CAnim.FastSpatial: return 350
        case CAnim.DefaultSpatial: return 500
        case CAnim.SlowSpatial: return 650
        case CAnim.FastEffects: return 150
        case CAnim.DefaultEffects: return 200
        case CAnim.SlowEffects: return 300
        default: return 200
        }
    }

    easing.type: {
        switch (type) {
        case CAnim.FastSpatial:
        case CAnim.DefaultSpatial:
        case CAnim.SlowSpatial:
            return Easing.OutBack
        default:
            return Easing.OutCubic
        }
    }
}
