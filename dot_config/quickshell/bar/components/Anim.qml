import QtQuick

// Tokens prontos de movimento (Caelestia / Material 3 expressive):
// durações e curvas copiadas de plugin/src/Caelestia/Config/tokens.hpp.
NumberAnimation {
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

    property int type: Anim.DefaultEffects

    duration: {
        switch (type) {
        case Anim.StandardSmall: return 200
        case Anim.Standard: return 400
        case Anim.StandardLarge: return 600
        case Anim.StandardExtraLarge: return 1000
        case Anim.FastSpatial: return 350
        case Anim.DefaultSpatial: return 500
        case Anim.SlowSpatial: return 650
        case Anim.FastEffects: return 150
        case Anim.DefaultEffects: return 200
        case Anim.SlowEffects: return 300
        default: return 200
        }
    }

    easing.type: {
        switch (type) {
        case Anim.FastSpatial:
        case Anim.DefaultSpatial:
        case Anim.SlowSpatial:
            return Easing.OutBack
        default:
            return Easing.OutCubic
        }
    }
}
