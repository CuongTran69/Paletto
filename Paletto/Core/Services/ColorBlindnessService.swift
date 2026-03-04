import Foundation

/// Simulates color blindness using Brettel/Viénot transformation matrices
final class ColorBlindnessService: ColorBlindnessServiceProtocol {

    // MARK: - Viénot et al. (1999) simulation matrices
    // Each matrix transforms linear RGB to simulated linear RGB

    /// Protanopia (red-blind) — missing L-cones
    private let protanopiaMatrix: [[CGFloat]] = [
        [0.152286, 1.052583, -0.204868],
        [0.114503, 0.786281,  0.099216],
        [-0.003882, -0.048116, 1.051998]
    ]

    /// Deuteranopia (green-blind) — missing M-cones
    private let deuteranopiaMatrix: [[CGFloat]] = [
        [0.367322, 0.860646, -0.227968],
        [0.280085, 0.672501,  0.047413],
        [-0.011820, 0.042940, 0.968881]
    ]

    /// Tritanopia (blue-blind) — missing S-cones
    private let tritanopiaMatrix: [[CGFloat]] = [
        [1.255528, -0.076749, -0.178779],
        [-0.078411, 0.930809,  0.147602],
        [0.004733, 0.691367,  0.303900]
    ]

    // MARK: - Public API

    func simulate(_ color: PaletteColor, type: ColorBlindnessType) -> PaletteColor {
        guard type != .normal else { return color }

        // Step 1: sRGB → Linear RGB
        let lr = linearize(color.red)
        let lg = linearize(color.green)
        let lb = linearize(color.blue)

        // Step 2: Apply transformation matrix
        let matrix = matrixFor(type)
        let sr = matrix[0][0] * lr + matrix[0][1] * lg + matrix[0][2] * lb
        let sg = matrix[1][0] * lr + matrix[1][1] * lg + matrix[1][2] * lb
        let sb = matrix[2][0] * lr + matrix[2][1] * lg + matrix[2][2] * lb

        // Step 3: Linear RGB → sRGB (with clamping)
        return PaletteColor(
            red: gammaCompress(clamp(sr)),
            green: gammaCompress(clamp(sg)),
            blue: gammaCompress(clamp(sb))
        )
    }

    func simulatePalette(_ palette: ColorPalette, type: ColorBlindnessType) -> PaletteSimulationResult {
        let simulated = palette.colors.map { color -> SimulatedColor in
            let sim = simulate(color, type: type)
            let dE = color.labColor.distance(to: sim.labColor)
            return SimulatedColor(original: color, simulated: sim, deltaE: dE)
        }

        // Find confusable pairs: colors that become indistinguishable (ΔE < 5) after simulation
        var confusable: [ConfusablePair] = []
        let simColors = simulated.map { $0.simulated }

        for i in 0..<simColors.count {
            for j in (i + 1)..<simColors.count {
                let dE = simColors[i].labColor.distance(to: simColors[j].labColor)
                if dE < 5.0 {
                    confusable.append(ConfusablePair(
                        index1: i,
                        index2: j,
                        color1: palette.colors[i],
                        color2: palette.colors[j],
                        simulatedDeltaE: dE
                    ))
                }
            }
        }

        return PaletteSimulationResult(
            type: type,
            simulatedColors: simulated,
            confusablePairs: confusable
        )
    }

    // MARK: - Private Helpers

    private func matrixFor(_ type: ColorBlindnessType) -> [[CGFloat]] {
        switch type {
        case .protanopia: return protanopiaMatrix
        case .deuteranopia: return deuteranopiaMatrix
        case .tritanopia: return tritanopiaMatrix
        case .normal: return [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
        }
    }

    private func linearize(_ v: CGFloat) -> CGFloat {
        v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
    }

    private func gammaCompress(_ v: CGFloat) -> CGFloat {
        v <= 0.0031308 ? 12.92 * v : 1.055 * pow(v, 1.0 / 2.4) - 0.055
    }

    private func clamp(_ v: CGFloat) -> CGFloat {
        max(0, min(1, v))
    }
}

