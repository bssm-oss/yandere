import AppKit

public enum VisualAssetRenderer {
    public enum Role {
        case background
        case character
        case cg
    }

    public static func image(for asset: VisualAsset, baseURL: URL?, role: Role) -> NSImage {
        if let baseURL {
            let fileURL = baseURL.appendingPathComponent(asset.path)
            if let image = NSImage(contentsOf: fileURL) {
                return image
            }
        }

        switch role {
        case .background:
            return makeBackground(for: asset)
        case .character:
            return makeCharacter(for: asset)
        case .cg:
            return makeCG(for: asset)
        }
    }

    private static func makeBackground(for asset: VisualAsset) -> NSImage {
        let size = NSSize(width: 1600, height: 900)
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }

        let palette = backgroundPalette(for: asset.id)
        NSGradient(starting: palette.top, ending: palette.bottom)?.draw(in: NSRect(origin: .zero, size: size), angle: 270)
        drawRain(in: NSRect(origin: .zero, size: size), density: asset.tags.contains("rain") ? 150 : 70)

        switch asset.id {
        case "bus_stop_evening":
            drawBusStop(size: size)
        case "retro_arcade":
            drawArcade(size: size)
        case "student_council_room":
            drawArchive(size: size)
        case "underpass_rain":
            drawUnderpass(size: size)
        case "locker_corridor":
            drawLockers(size: size)
        case "abandoned_platform":
            drawPlatform(size: size)
        case "school_rooftop":
            drawRooftop(size: size)
        case "locked_room":
            drawLockedRoom(size: size)
        case "water_tower":
            drawWaterTower(size: size)
        case "ai_kiosk":
            drawAIKiosk(size: size)
        case "mineral_aquarium":
            drawAquarium(size: size)
        case "old_library":
            drawLibrary(size: size)
        case "rain_shrine":
            drawRainShrine(size: size)
        case "old_apartment":
            drawOldApartment(size: size)
        case "water_lab":
            drawWaterLab(size: size)
        case "letter_room":
            drawLetterRoom(size: size)
        case "rain_radio_booth":
            drawRadioBooth(size: size)
        case "school_infirmary":
            drawInfirmary(size: size)
        case "memory_hallway":
            drawMemoryHallway(size: size)
        case "photo_booth":
            drawPhotoBooth(size: size)
        case "rooftop_greenhouse":
            drawGreenhouse(size: size)
        case "threshold_door":
            drawThresholdDoor(size: size)
        case "rain_stationery":
            drawRainStationery(size: size)
        case "lost_umbrella_room":
            drawLostUmbrellaRoom(size: size)
        case "midnight_laundromat":
            drawMidnightLaundromat(size: size)
        case "observation_deck":
            drawObservationDeck(size: size)
        case "old_teahouse":
            drawOldTeahouse(size: size)
        case "drainage_tunnel":
            drawDrainageTunnel(size: size)
        case "red_umbrella_return":
            drawRedUmbrellaReturn(size: size)
        case "clock_repair_shop":
            drawClockRepairShop(size: size)
        case "cassette_market":
            drawCassetteMarket(size: size)
        case "pedestrian_skybridge":
            drawPedestrianSkybridge(size: size)
        case "rain_history_museum":
            drawRainHistoryMuseum(size: size)
        case "phone_booth_alley":
            drawPhoneBoothAlley(size: size)
        case "purification_cathedral":
            drawPurificationCathedral(size: size)
        case "final_crosswalk":
            drawFinalCrosswalk(size: size)
        case "rain_tram_terminal":
            drawRainTramTerminal(size: size)
        case "school_server_room":
            drawSchoolServerRoom(size: size)
        case "hospital_rooftop":
            drawHospitalRooftop(size: size)
        case "archive_basement":
            drawArchiveBasement(size: size)
        case "mirror_bridge":
            drawMirrorBridge(size: size)
        case "reservoir_gate":
            drawReservoirGate(size: size)
        case "dawn_bus_loop":
            drawDawnBusLoop(size: size)
        case "sea_wall_mural":
            drawSeaWallMural(size: size)
        case "maintenance_elevator":
            drawMaintenanceElevator(size: size)
        case "rain_clinic_records":
            drawRainClinicRecords(size: size)
        case "weather_control_room":
            drawWeatherControlRoom(size: size)
        case "ferry_pier":
            drawFerryPier(size: size)
        case "flood_siren_tower":
            drawFloodSirenTower(size: size)
        case "weekend_station_clock":
            drawWeekendStationClock(size: size)
        default:
            drawCityStreet(size: size)
        }

        return image
    }

    private static func makeCharacter(for asset: VisualAsset) -> NSImage {
        let size = NSSize(width: 620, height: 900)
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }

        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        let palette = characterPalette(for: asset.id)
        let centerX = size.width * 0.52
        let body = NSBezierPath(roundedRect: NSRect(x: centerX - 130, y: 70, width: 260, height: 460), xRadius: 70, yRadius: 90)
        palette.uniform.setFill()
        body.fill()

        let neck = NSBezierPath(roundedRect: NSRect(x: centerX - 38, y: 500, width: 76, height: 80), xRadius: 24, yRadius: 24)
        palette.skin.setFill()
        neck.fill()

        let face = NSBezierPath(ovalIn: NSRect(x: centerX - 92, y: 552, width: 184, height: 220))
        palette.skin.setFill()
        face.fill()

        let hair = NSBezierPath(roundedRect: NSRect(x: centerX - 112, y: 642, width: 224, height: 174), xRadius: 78, yRadius: 82)
        palette.hair.setFill()
        hair.fill()

        drawEyes(centerX: centerX, y: 645, color: palette.eye)
        drawAccent(for: asset.id, centerX: centerX, size: size, color: palette.accent)

        if asset.id.contains("shadow") {
            drawUmbrella(centerX: centerX, size: size)
        }

        return image
    }

    private static func makeCG(for asset: VisualAsset) -> NSImage {
        let size = NSSize(width: 1400, height: 800)
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }

        let palette = backgroundPalette(for: asset.id)
        NSGradient(starting: palette.bottom, ending: palette.top)?.draw(in: NSRect(origin: .zero, size: size), angle: 12)
        drawRain(in: NSRect(origin: .zero, size: size), density: asset.tags.contains("rain") ? 140 : 84)

        NSColor.black.withAlphaComponent(0.18).setFill()
        NSBezierPath(roundedRect: NSRect(x: 90, y: 90, width: 1220, height: 620), xRadius: 26, yRadius: 26).fill()

        let accent = cgAccent(for: asset.id)
        accent.withAlphaComponent(0.68).setFill()
        NSBezierPath(ovalIn: NSRect(x: 260, y: 235, width: 360, height: 220)).fill()
        accent.withAlphaComponent(0.32).setFill()
        NSBezierPath(ovalIn: NSRect(x: 725, y: 280, width: 420, height: 170)).fill()

        NSColor.white.withAlphaComponent(0.70).setStroke()
        let line = NSBezierPath()
        line.lineWidth = 3
        line.move(to: CGPoint(x: 180, y: 570))
        line.curve(to: CGPoint(x: 1220, y: 250), controlPoint1: CGPoint(x: 430, y: 720), controlPoint2: CGPoint(x: 850, y: 80))
        line.stroke()

        drawCGSymbol(for: asset.id, size: size, accent: accent)
        return image
    }

    private static func backgroundPalette(for id: String) -> (top: NSColor, bottom: NSColor) {
        switch id {
        case "bus_stop_evening":
            return (NSColor(calibratedRed: 0.12, green: 0.10, blue: 0.13, alpha: 1), NSColor(calibratedRed: 0.40, green: 0.22, blue: 0.10, alpha: 1))
        case "retro_arcade":
            return (NSColor(calibratedRed: 0.03, green: 0.05, blue: 0.09, alpha: 1), NSColor(calibratedRed: 0.19, green: 0.07, blue: 0.12, alpha: 1))
        case "student_council_room":
            return (NSColor(calibratedRed: 0.07, green: 0.09, blue: 0.12, alpha: 1), NSColor(calibratedRed: 0.19, green: 0.22, blue: 0.25, alpha: 1))
        case "underpass_rain":
            return (NSColor(calibratedRed: 0.02, green: 0.03, blue: 0.05, alpha: 1), NSColor(calibratedRed: 0.13, green: 0.04, blue: 0.04, alpha: 1))
        case "locker_corridor":
            return (NSColor(calibratedRed: 0.11, green: 0.10, blue: 0.10, alpha: 1), NSColor(calibratedRed: 0.26, green: 0.10, blue: 0.10, alpha: 1))
        case "abandoned_platform":
            return (NSColor(calibratedRed: 0.03, green: 0.06, blue: 0.10, alpha: 1), NSColor(calibratedRed: 0.04, green: 0.14, blue: 0.22, alpha: 1))
        case "water_tower":
            return (NSColor(calibratedRed: 0.04, green: 0.09, blue: 0.12, alpha: 1), NSColor(calibratedRed: 0.12, green: 0.20, blue: 0.22, alpha: 1))
        case "ai_kiosk":
            return (NSColor(calibratedRed: 0.02, green: 0.04, blue: 0.07, alpha: 1), NSColor(calibratedRed: 0.08, green: 0.14, blue: 0.22, alpha: 1))
        case "mineral_aquarium":
            return (NSColor(calibratedRed: 0.00, green: 0.08, blue: 0.11, alpha: 1), NSColor(calibratedRed: 0.02, green: 0.25, blue: 0.27, alpha: 1))
        case "old_library":
            return (NSColor(calibratedRed: 0.09, green: 0.07, blue: 0.05, alpha: 1), NSColor(calibratedRed: 0.28, green: 0.18, blue: 0.10, alpha: 1))
        case "rain_shrine":
            return (NSColor(calibratedRed: 0.04, green: 0.06, blue: 0.05, alpha: 1), NSColor(calibratedRed: 0.24, green: 0.05, blue: 0.05, alpha: 1))
        case "old_apartment":
            return (NSColor(calibratedRed: 0.10, green: 0.08, blue: 0.07, alpha: 1), NSColor(calibratedRed: 0.22, green: 0.14, blue: 0.12, alpha: 1))
        case "water_lab":
            return (NSColor(calibratedRed: 0.02, green: 0.05, blue: 0.08, alpha: 1), NSColor(calibratedRed: 0.00, green: 0.18, blue: 0.24, alpha: 1))
        case "letter_room":
            return (NSColor(calibratedRed: 0.11, green: 0.07, blue: 0.06, alpha: 1), NSColor(calibratedRed: 0.31, green: 0.17, blue: 0.12, alpha: 1))
        case "rain_radio_booth":
            return (NSColor(calibratedRed: 0.03, green: 0.04, blue: 0.08, alpha: 1), NSColor(calibratedRed: 0.08, green: 0.11, blue: 0.24, alpha: 1))
        case "school_infirmary":
            return (NSColor(calibratedRed: 0.12, green: 0.15, blue: 0.17, alpha: 1), NSColor(calibratedRed: 0.34, green: 0.38, blue: 0.40, alpha: 1))
        case "memory_hallway":
            return (NSColor(calibratedRed: 0.04, green: 0.04, blue: 0.07, alpha: 1), NSColor(calibratedRed: 0.13, green: 0.07, blue: 0.16, alpha: 1))
        case "photo_booth":
            return (NSColor(calibratedRed: 0.08, green: 0.03, blue: 0.05, alpha: 1), NSColor(calibratedRed: 0.30, green: 0.06, blue: 0.10, alpha: 1))
        case "rooftop_greenhouse":
            return (NSColor(calibratedRed: 0.03, green: 0.09, blue: 0.08, alpha: 1), NSColor(calibratedRed: 0.10, green: 0.24, blue: 0.17, alpha: 1))
        case "threshold_door":
            return (NSColor(calibratedRed: 0.04, green: 0.05, blue: 0.08, alpha: 1), NSColor(calibratedRed: 0.29, green: 0.16, blue: 0.11, alpha: 1))
        case "rain_stationery":
            return (NSColor(calibratedRed: 0.10, green: 0.07, blue: 0.06, alpha: 1), NSColor(calibratedRed: 0.35, green: 0.20, blue: 0.12, alpha: 1))
        case "lost_umbrella_room":
            return (NSColor(calibratedRed: 0.08, green: 0.09, blue: 0.11, alpha: 1), NSColor(calibratedRed: 0.18, green: 0.20, blue: 0.24, alpha: 1))
        case "midnight_laundromat":
            return (NSColor(calibratedRed: 0.02, green: 0.05, blue: 0.08, alpha: 1), NSColor(calibratedRed: 0.07, green: 0.18, blue: 0.22, alpha: 1))
        case "observation_deck":
            return (NSColor(calibratedRed: 0.02, green: 0.04, blue: 0.08, alpha: 1), NSColor(calibratedRed: 0.05, green: 0.12, blue: 0.24, alpha: 1))
        case "old_teahouse":
            return (NSColor(calibratedRed: 0.14, green: 0.08, blue: 0.04, alpha: 1), NSColor(calibratedRed: 0.35, green: 0.20, blue: 0.10, alpha: 1))
        case "drainage_tunnel":
            return (NSColor(calibratedRed: 0.01, green: 0.05, blue: 0.06, alpha: 1), NSColor(calibratedRed: 0.00, green: 0.18, blue: 0.20, alpha: 1))
        case "red_umbrella_return":
            return (NSColor(calibratedRed: 0.05, green: 0.06, blue: 0.08, alpha: 1), NSColor(calibratedRed: 0.25, green: 0.08, blue: 0.08, alpha: 1))
        case "clock_repair_shop":
            return (NSColor(calibratedRed: 0.12, green: 0.08, blue: 0.04, alpha: 1), NSColor(calibratedRed: 0.28, green: 0.18, blue: 0.08, alpha: 1))
        case "cassette_market":
            return (NSColor(calibratedRed: 0.03, green: 0.04, blue: 0.07, alpha: 1), NSColor(calibratedRed: 0.18, green: 0.08, blue: 0.13, alpha: 1))
        case "pedestrian_skybridge":
            return (NSColor(calibratedRed: 0.03, green: 0.05, blue: 0.08, alpha: 1), NSColor(calibratedRed: 0.16, green: 0.05, blue: 0.07, alpha: 1))
        case "rain_history_museum":
            return (NSColor(calibratedRed: 0.08, green: 0.10, blue: 0.12, alpha: 1), NSColor(calibratedRed: 0.20, green: 0.24, blue: 0.28, alpha: 1))
        case "phone_booth_alley":
            return (NSColor(calibratedRed: 0.04, green: 0.03, blue: 0.06, alpha: 1), NSColor(calibratedRed: 0.22, green: 0.05, blue: 0.10, alpha: 1))
        case "purification_cathedral":
            return (NSColor(calibratedRed: 0.01, green: 0.05, blue: 0.07, alpha: 1), NSColor(calibratedRed: 0.02, green: 0.18, blue: 0.23, alpha: 1))
        case "final_crosswalk":
            return (NSColor(calibratedRed: 0.02, green: 0.03, blue: 0.05, alpha: 1), NSColor(calibratedRed: 0.18, green: 0.08, blue: 0.08, alpha: 1))
        case "rain_tram_terminal":
            return (NSColor(calibratedRed: 0.03, green: 0.05, blue: 0.07, alpha: 1), NSColor(calibratedRed: 0.20, green: 0.08, blue: 0.08, alpha: 1))
        case "school_server_room":
            return (NSColor(calibratedRed: 0.02, green: 0.04, blue: 0.08, alpha: 1), NSColor(calibratedRed: 0.06, green: 0.13, blue: 0.24, alpha: 1))
        case "hospital_rooftop":
            return (NSColor(calibratedRed: 0.12, green: 0.13, blue: 0.15, alpha: 1), NSColor(calibratedRed: 0.26, green: 0.30, blue: 0.34, alpha: 1))
        case "archive_basement":
            return (NSColor(calibratedRed: 0.05, green: 0.06, blue: 0.07, alpha: 1), NSColor(calibratedRed: 0.14, green: 0.17, blue: 0.18, alpha: 1))
        case "mirror_bridge":
            return (NSColor(calibratedRed: 0.03, green: 0.05, blue: 0.08, alpha: 1), NSColor(calibratedRed: 0.12, green: 0.08, blue: 0.16, alpha: 1))
        case "reservoir_gate":
            return (NSColor(calibratedRed: 0.01, green: 0.05, blue: 0.07, alpha: 1), NSColor(calibratedRed: 0.00, green: 0.14, blue: 0.20, alpha: 1))
        case "dawn_bus_loop":
            return (NSColor(calibratedRed: 0.06, green: 0.05, blue: 0.07, alpha: 1), NSColor(calibratedRed: 0.22, green: 0.12, blue: 0.10, alpha: 1))
        case "sea_wall_mural":
            return (NSColor(calibratedRed: 0.03, green: 0.07, blue: 0.09, alpha: 1), NSColor(calibratedRed: 0.17, green: 0.20, blue: 0.22, alpha: 1))
        case "maintenance_elevator":
            return (NSColor(calibratedRed: 0.04, green: 0.05, blue: 0.07, alpha: 1), NSColor(calibratedRed: 0.20, green: 0.22, blue: 0.25, alpha: 1))
        case "rain_clinic_records":
            return (NSColor(calibratedRed: 0.10, green: 0.12, blue: 0.14, alpha: 1), NSColor(calibratedRed: 0.26, green: 0.20, blue: 0.23, alpha: 1))
        case "weather_control_room":
            return (NSColor(calibratedRed: 0.01, green: 0.04, blue: 0.07, alpha: 1), NSColor(calibratedRed: 0.05, green: 0.14, blue: 0.20, alpha: 1))
        case "ferry_pier":
            return (NSColor(calibratedRed: 0.01, green: 0.04, blue: 0.06, alpha: 1), NSColor(calibratedRed: 0.10, green: 0.08, blue: 0.09, alpha: 1))
        case "flood_siren_tower":
            return (NSColor(calibratedRed: 0.03, green: 0.04, blue: 0.05, alpha: 1), NSColor(calibratedRed: 0.18, green: 0.05, blue: 0.05, alpha: 1))
        case "weekend_station_clock":
            return (NSColor(calibratedRed: 0.07, green: 0.06, blue: 0.08, alpha: 1), NSColor(calibratedRed: 0.30, green: 0.22, blue: 0.16, alpha: 1))
        case "locked_room":
            return (NSColor(calibratedRed: 0.12, green: 0.08, blue: 0.07, alpha: 1), NSColor(calibratedRed: 0.30, green: 0.18, blue: 0.12, alpha: 1))
        default:
            return (NSColor(calibratedRed: 0.03, green: 0.05, blue: 0.09, alpha: 1), NSColor(calibratedRed: 0.08, green: 0.11, blue: 0.16, alpha: 1))
        }
    }

    private static func characterPalette(for id: String) -> (skin: NSColor, hair: NSColor, eye: NSColor, uniform: NSColor, accent: NSColor) {
        switch id {
        case "airi_normal", "airi_raincoat_close", "airi_hospital_roof":
            return (.init(calibratedRed: 0.92, green: 0.78, blue: 0.68, alpha: 1), .init(calibratedRed: 0.18, green: 0.10, blue: 0.06, alpha: 1), .init(calibratedRed: 0.52, green: 0.36, blue: 0.18, alpha: 1), .init(calibratedRed: 0.19, green: 0.22, blue: 0.28, alpha: 1), .systemOrange)
        case "yuka_normal", "yuka_lab_coat", "yuka_server", "yuka_elevator_panel", "yuka_weather_terminal":
            return (.init(calibratedRed: 0.88, green: 0.80, blue: 0.74, alpha: 1), .init(calibratedRed: 0.72, green: 0.76, blue: 0.82, alpha: 1), .init(calibratedRed: 0.28, green: 0.42, blue: 0.62, alpha: 1), .init(calibratedRed: 0.12, green: 0.14, blue: 0.20, alpha: 1), .systemBlue)
        case "shadow_kurogasa", "shadow_young_photo", "shadow_reservoir", "shadow_siren_tower":
            return (.init(calibratedRed: 0.74, green: 0.68, blue: 0.64, alpha: 1), .black, .init(calibratedRed: 0.45, green: 0.05, blue: 0.05, alpha: 1), .init(calibratedRed: 0.02, green: 0.02, blue: 0.03, alpha: 1), .systemRed)
        case "haru_reflection", "haru_umbrella_reflection":
            return (.init(calibratedRed: 0.82, green: 0.74, blue: 0.68, alpha: 0.78), .init(calibratedRed: 0.08, green: 0.07, blue: 0.07, alpha: 0.78), .init(calibratedRed: 0.24, green: 0.30, blue: 0.36, alpha: 0.78), .init(calibratedRed: 0.12, green: 0.15, blue: 0.20, alpha: 0.62), .systemGray)
        case "umbrella_keeper_ai", "cassette_vendor_ai", "archive_clerk_ai", "clinic_nurse_ai":
            return (.init(calibratedRed: 0.62, green: 0.70, blue: 0.80, alpha: 0.86), .init(calibratedRed: 0.03, green: 0.05, blue: 0.08, alpha: 0.82), .systemCyan, .init(calibratedRed: 0.05, green: 0.08, blue: 0.12, alpha: 0.70), .systemBlue)
        default:
            return (.init(calibratedRed: 0.90, green: 0.78, blue: 0.72, alpha: 1), .init(calibratedRed: 0.02, green: 0.02, blue: 0.03, alpha: 1), .systemRed, .init(calibratedRed: 0.12, green: 0.14, blue: 0.19, alpha: 1), .systemRed)
        }
    }

    private static func drawRain(in rect: NSRect, density: Int) {
        NSColor.white.withAlphaComponent(0.18).setStroke()
        for index in 0..<density {
            let x = CGFloat((index * 73) % Int(rect.width))
            let y = CGFloat((index * 137) % Int(rect.height))
            let path = NSBezierPath()
            path.lineWidth = CGFloat(1 + (index % 3)) * 0.45
            path.move(to: CGPoint(x: x, y: y))
            path.line(to: CGPoint(x: x + 18, y: y - 62))
            path.stroke()
        }
    }

    private static func drawBusStop(size: NSSize) {
        NSColor.black.withAlphaComponent(0.34).setFill()
        NSBezierPath(roundedRect: NSRect(x: 170, y: 220, width: 640, height: 360), xRadius: 18, yRadius: 18).fill()
        NSColor(calibratedRed: 1.0, green: 0.62, blue: 0.24, alpha: 0.36).setFill()
        NSRect(x: 220, y: 452, width: 190, height: 66).fill()
    }

    private static func drawArcade(size: NSSize) {
        for index in 0..<5 {
            let x = 180 + CGFloat(index) * 230
            NSColor.black.withAlphaComponent(0.48).setFill()
            NSBezierPath(roundedRect: NSRect(x: x, y: 180, width: 150, height: 420), xRadius: 14, yRadius: 14).fill()
            [NSColor.systemCyan, .systemPink, .systemYellow, .systemBlue, .systemRed][index].withAlphaComponent(0.44).setFill()
            NSRect(x: x + 20, y: 410, width: 110, height: 88).fill()
        }
    }

    private static func drawArchive(size: NSSize) {
        for index in 0..<6 {
            let x = 120 + CGFloat(index) * 210
            NSColor(calibratedWhite: 0.72, alpha: 0.12).setFill()
            NSRect(x: x, y: 170, width: 150, height: 520).fill()
            NSColor.white.withAlphaComponent(0.16).setStroke()
            NSBezierPath(rect: NSRect(x: x, y: 170, width: 150, height: 520)).stroke()
        }
    }

    private static func drawUnderpass(size: NSSize) {
        NSColor.black.withAlphaComponent(0.42).setFill()
        NSRect(x: 0, y: 0, width: size.width, height: 360).fill()
        NSColor.systemRed.withAlphaComponent(0.32).setFill()
        NSBezierPath(ovalIn: NSRect(x: 1030, y: 260, width: 260, height: 38)).fill()
    }

    private static func drawLockers(size: NSSize) {
        for index in 0..<12 {
            let x = 80 + CGFloat(index) * 120
            NSColor(calibratedRed: 0.20, green: 0.20, blue: 0.22, alpha: 0.72).setFill()
            NSRect(x: x, y: 140, width: 92, height: 560).fill()
        }
        NSColor.systemRed.withAlphaComponent(0.78).setFill()
        NSRect(x: 780, y: 420, width: 96, height: 58).fill()
    }

    private static func drawPlatform(size: NSSize) {
        NSColor.systemBlue.withAlphaComponent(0.20).setFill()
        NSRect(x: 0, y: 600, width: size.width, height: 68).fill()
        NSColor.white.withAlphaComponent(0.16).setStroke()
        for offset in stride(from: CGFloat(220), through: CGFloat(560), by: 90) {
            let path = NSBezierPath()
            path.lineWidth = 4
            path.move(to: CGPoint(x: 0, y: offset))
            path.line(to: CGPoint(x: size.width, y: offset - 170))
            path.stroke()
        }
    }

    private static func drawRooftop(size: NSSize) {
        NSColor.white.withAlphaComponent(0.18).setStroke()
        for index in 0..<9 {
            let path = NSBezierPath()
            path.lineWidth = 2
            let x = 200 + CGFloat(index) * 135
            path.move(to: CGPoint(x: x, y: 270))
            path.line(to: CGPoint(x: x + 70, y: 680))
            path.stroke()
        }
    }

    private static func drawLockedRoom(size: NSSize) {
        NSColor(calibratedRed: 0.9, green: 0.52, blue: 0.26, alpha: 0.18).setFill()
        NSBezierPath(ovalIn: NSRect(x: 360, y: 190, width: 420, height: 260)).fill()
        NSColor.white.withAlphaComponent(0.14).setFill()
        for index in 0..<7 {
            NSBezierPath(ovalIn: NSRect(x: 220 + CGFloat(index) * 150, y: 520, width: 58, height: 58)).fill()
        }
    }

    private static func drawWaterTower(size: NSSize) {
        NSColor(calibratedWhite: 0.05, alpha: 0.56).setFill()
        NSRect(x: 710, y: 170, width: 70, height: 450).fill()
        NSBezierPath(ovalIn: NSRect(x: 540, y: 560, width: 420, height: 190)).fill()
        NSColor.systemCyan.withAlphaComponent(0.28).setFill()
        NSRect(x: 260, y: 210, width: 220, height: 76).fill()
    }

    private static func drawAIKiosk(size: NSSize) {
        NSColor.black.withAlphaComponent(0.50).setFill()
        NSBezierPath(roundedRect: NSRect(x: 620, y: 160, width: 360, height: 590), xRadius: 22, yRadius: 22).fill()
        NSColor.systemBlue.withAlphaComponent(0.48).setFill()
        NSBezierPath(roundedRect: NSRect(x: 670, y: 470, width: 260, height: 150), xRadius: 18, yRadius: 18).fill()
        NSColor.white.withAlphaComponent(0.28).setFill()
        for index in 0..<5 {
            NSRect(x: 705, y: 525 - CGFloat(index) * 22, width: 190, height: 6).fill()
        }
    }

    private static func drawAquarium(size: NSSize) {
        for index in 0..<4 {
            let x = 160 + CGFloat(index) * 320
            NSColor.systemCyan.withAlphaComponent(0.22).setFill()
            NSBezierPath(roundedRect: NSRect(x: x, y: 210, width: 250, height: 440), xRadius: 16, yRadius: 16).fill()
            NSColor.systemRed.withAlphaComponent(0.54).setFill()
            NSBezierPath(ovalIn: NSRect(x: x + 92, y: 410, width: 66, height: 28)).fill()
        }
    }

    private static func drawLibrary(size: NSSize) {
        for index in 0..<7 {
            let x = 80 + CGFloat(index) * 210
            NSColor(calibratedRed: 0.20, green: 0.12, blue: 0.06, alpha: 0.54).setFill()
            NSRect(x: x, y: 170, width: 150, height: 520).fill()
        }
        NSColor(calibratedRed: 1.0, green: 0.72, blue: 0.36, alpha: 0.30).setFill()
        NSBezierPath(ovalIn: NSRect(x: 580, y: 360, width: 320, height: 180)).fill()
    }

    private static func drawRainShrine(size: NSSize) {
        NSColor.black.withAlphaComponent(0.40).setFill()
        NSBezierPath(roundedRect: NSRect(x: 520, y: 220, width: 520, height: 360), xRadius: 18, yRadius: 18).fill()
        NSColor.systemRed.withAlphaComponent(0.72).setStroke()
        for index in 0..<12 {
            let path = NSBezierPath()
            path.lineWidth = 4
            let x = 180 + CGFloat(index) * 105
            path.move(to: CGPoint(x: x, y: 680))
            path.curve(to: CGPoint(x: x + 70, y: 500), controlPoint1: CGPoint(x: x - 30, y: 610), controlPoint2: CGPoint(x: x + 120, y: 570))
            path.stroke()
        }
    }

    private static func drawOldApartment(size: NSSize) {
        NSColor.black.withAlphaComponent(0.30).setFill()
        NSBezierPath(roundedRect: NSRect(x: 240, y: 150, width: 1030, height: 620), xRadius: 18, yRadius: 18).fill()
        for row in 0..<3 {
            for column in 0..<6 {
                NSColor.white.withAlphaComponent(0.16).setFill()
                NSRect(x: 330 + CGFloat(column) * 135, y: 260 + CGFloat(row) * 130, width: 86, height: 92).fill()
            }
        }
    }

    private static func drawWaterLab(size: NSSize) {
        NSColor.systemCyan.withAlphaComponent(0.22).setFill()
        for index in 0..<8 {
            let x = 210 + CGFloat(index) * 140
            NSBezierPath(roundedRect: NSRect(x: x, y: 240, width: 48, height: 310), xRadius: 20, yRadius: 20).fill()
        }
        NSColor.systemRed.withAlphaComponent(0.28).setFill()
        NSRect(x: 0, y: 650, width: size.width, height: 42).fill()
    }

    private static func drawLetterRoom(size: NSSize) {
        NSColor(calibratedRed: 1.0, green: 0.76, blue: 0.42, alpha: 0.18).setFill()
        NSBezierPath(ovalIn: NSRect(x: 520, y: 280, width: 520, height: 280)).fill()
        NSColor.white.withAlphaComponent(0.30).setStroke()
        for index in 0..<5 {
            let y = 610 - CGFloat(index) * 82
            let cord = NSBezierPath()
            cord.lineWidth = 2
            cord.move(to: CGPoint(x: 170, y: y))
            cord.line(to: CGPoint(x: 1360, y: y + CGFloat(index % 2) * 28))
            cord.stroke()
            for column in 0..<6 {
                NSColor(calibratedRed: 0.92, green: 0.82, blue: 0.68, alpha: 0.52).setFill()
                NSRect(x: 220 + CGFloat(column) * 185, y: y - 48, width: 108, height: 62).fill()
            }
        }
    }

    private static func drawRadioBooth(size: NSSize) {
        NSColor.black.withAlphaComponent(0.42).setFill()
        NSBezierPath(roundedRect: NSRect(x: 260, y: 180, width: 990, height: 520), xRadius: 22, yRadius: 22).fill()
        NSColor.systemBlue.withAlphaComponent(0.34).setFill()
        for index in 0..<8 {
            NSRect(x: 360 + CGFloat(index) * 78, y: 465, width: 42, height: CGFloat(40 + (index % 4) * 36)).fill()
        }
        NSColor.white.withAlphaComponent(0.18).setStroke()
        NSBezierPath(ovalIn: NSRect(x: 830, y: 285, width: 240, height: 240)).stroke()
    }

    private static func drawInfirmary(size: NSSize) {
        NSColor.white.withAlphaComponent(0.26).setFill()
        for index in 0..<5 {
            NSRect(x: 120 + CGFloat(index) * 190, y: 160, width: 120, height: 600).fill()
        }
        NSColor.black.withAlphaComponent(0.30).setFill()
        NSBezierPath(roundedRect: NSRect(x: 500, y: 220, width: 620, height: 170), xRadius: 26, yRadius: 26).fill()
        NSColor.systemRed.withAlphaComponent(0.38).setStroke()
        let pulse = NSBezierPath()
        pulse.lineWidth = 6
        pulse.move(to: CGPoint(x: 560, y: 530))
        pulse.line(to: CGPoint(x: 650, y: 530))
        pulse.line(to: CGPoint(x: 690, y: 600))
        pulse.line(to: CGPoint(x: 735, y: 450))
        pulse.line(to: CGPoint(x: 780, y: 530))
        pulse.line(to: CGPoint(x: 1040, y: 530))
        pulse.stroke()
    }

    private static func drawMemoryHallway(size: NSSize) {
        NSColor.black.withAlphaComponent(0.28).setFill()
        for index in 0..<8 {
            let inset = CGFloat(index) * 72
            NSBezierPath(rect: NSRect(x: 160 + inset, y: 120 + inset * 0.38, width: size.width - 320 - inset * 2, height: size.height - 240 - inset * 0.76)).stroke()
        }
        NSColor.systemRed.withAlphaComponent(0.40).setStroke()
        let thread = NSBezierPath()
        thread.lineWidth = 5
        thread.move(to: CGPoint(x: 120, y: 230))
        thread.curve(to: CGPoint(x: 1320, y: 580), controlPoint1: CGPoint(x: 360, y: 80), controlPoint2: CGPoint(x: 840, y: 760))
        thread.stroke()
    }

    private static func drawPhotoBooth(size: NSSize) {
        NSColor.systemRed.withAlphaComponent(0.34).setFill()
        NSBezierPath(roundedRect: NSRect(x: 430, y: 150, width: 520, height: 620), xRadius: 28, yRadius: 28).fill()
        NSColor.black.withAlphaComponent(0.48).setFill()
        NSRect(x: 675, y: 150, width: 310, height: 620).fill()
        NSColor.white.withAlphaComponent(0.76).setFill()
        for index in 0..<4 {
            NSRect(x: 250 + CGFloat(index) * 120, y: 240, width: 82, height: 110).fill()
        }
    }

    private static func drawGreenhouse(size: NSSize) {
        NSColor.white.withAlphaComponent(0.18).setStroke()
        for index in 0..<9 {
            let x = 160 + CGFloat(index) * 145
            let rib = NSBezierPath()
            rib.lineWidth = 3
            rib.move(to: CGPoint(x: x, y: 170))
            rib.line(to: CGPoint(x: x + 90, y: 740))
            rib.stroke()
        }
        NSColor.systemGreen.withAlphaComponent(0.32).setFill()
        for index in 0..<10 {
            NSBezierPath(ovalIn: NSRect(x: 190 + CGFloat(index) * 120, y: 170 + CGFloat(index % 3) * 45, width: 180, height: 80)).fill()
        }
    }

    private static func drawThresholdDoor(size: NSSize) {
        NSColor(calibratedRed: 0.95, green: 0.56, blue: 0.30, alpha: 0.28).setFill()
        NSRect(x: 810, y: 140, width: 430, height: 650).fill()
        NSColor.black.withAlphaComponent(0.58).setFill()
        NSRect(x: 360, y: 120, width: 420, height: 690).fill()
        NSColor.systemRed.withAlphaComponent(0.26).setFill()
        NSBezierPath(ovalIn: NSRect(x: 640, y: 190, width: 500, height: 120)).fill()
    }

    private static func drawRainStationery(size: NSSize) {
        NSColor(calibratedRed: 1.0, green: 0.72, blue: 0.38, alpha: 0.22).setFill()
        NSBezierPath(ovalIn: NSRect(x: 460, y: 270, width: 560, height: 330)).fill()
        NSColor(calibratedRed: 0.92, green: 0.82, blue: 0.64, alpha: 0.56).setFill()
        for row in 0..<3 {
            for column in 0..<5 {
                NSRect(x: 260 + CGFloat(column) * 205, y: 260 + CGFloat(row) * 112, width: 140, height: 74).fill()
            }
        }
        NSColor.systemRed.withAlphaComponent(0.58).setFill()
        for index in 0..<5 {
            NSBezierPath(ovalIn: NSRect(x: 350 + CGFloat(index) * 155, y: 610, width: 38, height: 82)).fill()
        }
    }

    private static func drawLostUmbrellaRoom(size: NSSize) {
        NSColor.white.withAlphaComponent(0.20).setStroke()
        for index in 0..<13 {
            let x = 110 + CGFloat(index) * 105
            let umbrella = NSBezierPath()
            umbrella.lineWidth = 3
            umbrella.move(to: CGPoint(x: x - 42, y: 610))
            umbrella.curve(to: CGPoint(x: x + 42, y: 610), controlPoint1: CGPoint(x: x - 28, y: 675), controlPoint2: CGPoint(x: x + 28, y: 675))
            umbrella.line(to: CGPoint(x: x, y: 300))
            umbrella.stroke()
        }
        NSColor.systemRed.withAlphaComponent(0.72).setStroke()
        let red = NSBezierPath()
        red.lineWidth = 7
        red.move(to: CGPoint(x: 810, y: 640))
        red.curve(to: CGPoint(x: 990, y: 640), controlPoint1: CGPoint(x: 850, y: 750), controlPoint2: CGPoint(x: 950, y: 750))
        red.line(to: CGPoint(x: 900, y: 255))
        red.stroke()
    }

    private static func drawMidnightLaundromat(size: NSSize) {
        for index in 0..<6 {
            let x = 180 + CGFloat(index) * 190
            NSColor.black.withAlphaComponent(0.42).setFill()
            NSBezierPath(roundedRect: NSRect(x: x, y: 215, width: 150, height: 420), xRadius: 18, yRadius: 18).fill()
            NSColor.systemCyan.withAlphaComponent(0.20).setFill()
            NSBezierPath(ovalIn: NSRect(x: x + 22, y: 385, width: 106, height: 106)).fill()
        }
        NSColor.systemRed.withAlphaComponent(0.50).setStroke()
        let ribbon = NSBezierPath()
        ribbon.lineWidth = 6
        ribbon.move(to: CGPoint(x: 560, y: 440))
        ribbon.curve(to: CGPoint(x: 690, y: 440), controlPoint1: CGPoint(x: 610, y: 530), controlPoint2: CGPoint(x: 650, y: 350))
        ribbon.stroke()
    }

    private static func drawObservationDeck(size: NSSize) {
        NSColor.white.withAlphaComponent(0.16).setStroke()
        for index in 0..<10 {
            let x = CGFloat(index) * 170
            let path = NSBezierPath()
            path.lineWidth = 2
            path.move(to: CGPoint(x: x, y: 120))
            path.line(to: CGPoint(x: size.width * 0.50, y: 760))
            path.stroke()
        }
        NSColor.systemBlue.withAlphaComponent(0.24).setFill()
        for index in 0..<9 {
            NSRect(x: 180 + CGFloat(index) * 135, y: 220 + CGFloat(index % 3) * 58, width: 66, height: 180).fill()
        }
        NSColor.systemRed.withAlphaComponent(0.48).setStroke()
        let route = NSBezierPath()
        route.lineWidth = 5
        route.move(to: CGPoint(x: 280, y: 330))
        route.curve(to: CGPoint(x: 1180, y: 580), controlPoint1: CGPoint(x: 520, y: 620), controlPoint2: CGPoint(x: 880, y: 190))
        route.stroke()
    }

    private static func drawOldTeahouse(size: NSSize) {
        NSColor(calibratedRed: 0.95, green: 0.64, blue: 0.32, alpha: 0.24).setFill()
        NSBezierPath(ovalIn: NSRect(x: 500, y: 250, width: 500, height: 300)).fill()
        NSColor.black.withAlphaComponent(0.30).setFill()
        NSBezierPath(roundedRect: NSRect(x: 360, y: 210, width: 810, height: 120), xRadius: 24, yRadius: 24).fill()
        NSColor.white.withAlphaComponent(0.42).setStroke()
        for index in 0..<2 {
            NSBezierPath(ovalIn: NSRect(x: 570 + CGFloat(index) * 220, y: 355, width: 132, height: 72)).stroke()
        }
        NSColor.systemRed.withAlphaComponent(0.65).setFill()
        NSBezierPath(roundedRect: NSRect(x: 743, y: 423, width: 34, height: 34), xRadius: 5, yRadius: 5).fill()
    }

    private static func drawDrainageTunnel(size: NSSize) {
        NSColor.black.withAlphaComponent(0.44).setFill()
        NSBezierPath(ovalIn: NSRect(x: 160, y: 160, width: 1180, height: 600)).fill()
        NSColor.systemCyan.withAlphaComponent(0.34).setFill()
        NSBezierPath(roundedRect: NSRect(x: 0, y: 90, width: size.width, height: 240), xRadius: 70, yRadius: 70).fill()
        NSColor.systemRed.withAlphaComponent(0.58).setStroke()
        let valve = NSBezierPath(ovalIn: NSRect(x: 680, y: 400, width: 135, height: 135))
        valve.lineWidth = 8
        valve.stroke()
    }

    private static func drawRedUmbrellaReturn(size: NSSize) {
        NSColor.black.withAlphaComponent(0.36).setFill()
        NSBezierPath(roundedRect: NSRect(x: 455, y: 170, width: 590, height: 210), xRadius: 24, yRadius: 24).fill()
        NSColor.white.withAlphaComponent(0.18).setFill()
        NSRect(x: 0, y: 390, width: size.width, height: 120).fill()
        NSColor.systemRed.withAlphaComponent(0.78).setStroke()
        let umbrella = NSBezierPath()
        umbrella.lineWidth = 9
        umbrella.move(to: CGPoint(x: 620, y: 640))
        umbrella.curve(to: CGPoint(x: 890, y: 640), controlPoint1: CGPoint(x: 680, y: 790), controlPoint2: CGPoint(x: 830, y: 790))
        umbrella.line(to: CGPoint(x: 755, y: 240))
        umbrella.stroke()
    }

    private static func drawClockRepairShop(size: NSSize) {
        NSColor(calibratedRed: 1.0, green: 0.70, blue: 0.30, alpha: 0.18).setFill()
        NSBezierPath(ovalIn: NSRect(x: 470, y: 250, width: 520, height: 350)).fill()
        NSColor.white.withAlphaComponent(0.34).setStroke()
        for row in 0..<2 {
            for column in 0..<6 {
                let rect = NSRect(x: 210 + CGFloat(column) * 185, y: 290 + CGFloat(row) * 190, width: 112, height: 112)
                let clock = NSBezierPath(ovalIn: rect)
                clock.lineWidth = 3
                clock.stroke()
                let hand = NSBezierPath()
                hand.lineWidth = 2
                hand.move(to: CGPoint(x: rect.midX, y: rect.midY))
                hand.line(to: CGPoint(x: rect.midX + 28, y: rect.midY + 36))
                hand.stroke()
            }
        }
        NSColor.systemRed.withAlphaComponent(0.58).setStroke()
        let second = NSBezierPath()
        second.lineWidth = 5
        second.move(to: CGPoint(x: 745, y: 450))
        second.line(to: CGPoint(x: 745, y: 610))
        second.stroke()
    }

    private static func drawCassetteMarket(size: NSSize) {
        for row in 0..<4 {
            for column in 0..<7 {
                let x = 170 + CGFloat(column) * 160
                let y = 220 + CGFloat(row) * 105
                NSColor.black.withAlphaComponent(0.38).setFill()
                NSBezierPath(roundedRect: NSRect(x: x, y: y, width: 112, height: 70), xRadius: 10, yRadius: 10).fill()
                NSColor.white.withAlphaComponent(0.28).setStroke()
                NSBezierPath(ovalIn: NSRect(x: x + 16, y: y + 20, width: 24, height: 24)).stroke()
                NSBezierPath(ovalIn: NSRect(x: x + 72, y: y + 20, width: 24, height: 24)).stroke()
            }
        }
        NSColor.systemRed.withAlphaComponent(0.62).setFill()
        NSBezierPath(roundedRect: NSRect(x: 710, y: 570, width: 150, height: 92), xRadius: 12, yRadius: 12).fill()
    }

    private static func drawPedestrianSkybridge(size: NSSize) {
        NSColor.white.withAlphaComponent(0.16).setStroke()
        for index in 0..<8 {
            let y = 260 + CGFloat(index) * 38
            let rail = NSBezierPath()
            rail.lineWidth = 3
            rail.move(to: CGPoint(x: 120, y: y))
            rail.line(to: CGPoint(x: 1360, y: y + CGFloat(index % 2) * 12))
            rail.stroke()
        }
        NSColor.systemRed.withAlphaComponent(0.38).setFill()
        for index in 0..<12 {
            NSBezierPath(ovalIn: NSRect(x: 90 + CGFloat(index) * 120, y: 130, width: 60, height: 18)).fill()
        }
        NSColor.black.withAlphaComponent(0.45).setFill()
        NSRect(x: 700, y: 540, width: 64, height: 120).fill()
    }

    private static func drawRainHistoryMuseum(size: NSSize) {
        NSColor.white.withAlphaComponent(0.18).setFill()
        for index in 0..<5 {
            let x = 210 + CGFloat(index) * 230
            NSBezierPath(roundedRect: NSRect(x: x, y: 200, width: 150, height: 460), xRadius: 14, yRadius: 14).fill()
            NSColor.systemCyan.withAlphaComponent(0.22).setFill()
            NSBezierPath(ovalIn: NSRect(x: x + 40, y: 375, width: 70, height: 110)).fill()
        }
        NSColor.systemRed.withAlphaComponent(0.52).setStroke()
        let ribbon = NSBezierPath()
        ribbon.lineWidth = 6
        ribbon.move(to: CGPoint(x: 768, y: 585))
        ribbon.curve(to: CGPoint(x: 845, y: 500), controlPoint1: CGPoint(x: 805, y: 640), controlPoint2: CGPoint(x: 850, y: 550))
        ribbon.stroke()
    }

    private static func drawPhoneBoothAlley(size: NSSize) {
        NSColor.black.withAlphaComponent(0.52).setFill()
        NSBezierPath(roundedRect: NSRect(x: 575, y: 150, width: 360, height: 650), xRadius: 22, yRadius: 22).fill()
        NSColor.white.withAlphaComponent(0.18).setFill()
        NSRect(x: 625, y: 350, width: 260, height: 340).fill()
        NSColor.systemRed.withAlphaComponent(0.58).setStroke()
        let cord = NSBezierPath()
        cord.lineWidth = 6
        cord.move(to: CGPoint(x: 700, y: 480))
        cord.curve(to: CGPoint(x: 820, y: 300), controlPoint1: CGPoint(x: 630, y: 370), controlPoint2: CGPoint(x: 910, y: 410))
        cord.stroke()
    }

    private static func drawPurificationCathedral(size: NSSize) {
        NSColor.systemCyan.withAlphaComponent(0.22).setFill()
        for index in 0..<6 {
            let x = 210 + CGFloat(index) * 190
            NSBezierPath(roundedRect: NSRect(x: x, y: 150, width: 96, height: 620), xRadius: 46, yRadius: 46).fill()
        }
        NSColor.white.withAlphaComponent(0.16).setStroke()
        for index in 0..<5 {
            let arch = NSBezierPath()
            arch.lineWidth = 4
            let x = 260 + CGFloat(index) * 220
            arch.move(to: CGPoint(x: x, y: 180))
            arch.curve(to: CGPoint(x: x + 170, y: 180), controlPoint1: CGPoint(x: x + 20, y: 690), controlPoint2: CGPoint(x: x + 150, y: 690))
            arch.stroke()
        }
        NSColor.systemRed.withAlphaComponent(0.42).setFill()
        NSBezierPath(ovalIn: NSRect(x: 690, y: 370, width: 150, height: 150)).fill()
    }

    private static func drawFinalCrosswalk(size: NSSize) {
        NSColor.white.withAlphaComponent(0.30).setFill()
        for index in 0..<7 {
            NSRect(x: 160 + CGFloat(index) * 185, y: 290, width: 116, height: 42).fill()
        }
        NSColor.systemRed.withAlphaComponent(0.50).setFill()
        NSBezierPath(ovalIn: NSRect(x: 560, y: 590, width: 78, height: 78)).fill()
        NSColor.systemGreen.withAlphaComponent(0.46).setFill()
        NSBezierPath(ovalIn: NSRect(x: 860, y: 590, width: 78, height: 78)).fill()
        NSColor.systemRed.withAlphaComponent(0.30).setFill()
        NSBezierPath(ovalIn: NSRect(x: 520, y: 170, width: 460, height: 95)).fill()
    }

    private static func drawRainTramTerminal(size: NSSize) {
        NSColor.white.withAlphaComponent(0.18).setStroke()
        for offset in stride(from: CGFloat(250), through: CGFloat(600), by: 90) {
            let rail = NSBezierPath()
            rail.lineWidth = 5
            rail.move(to: CGPoint(x: 120, y: offset))
            rail.line(to: CGPoint(x: size.width - 120, y: offset - 170))
            rail.stroke()
        }
        NSColor.systemRed.withAlphaComponent(0.45).setFill()
        NSBezierPath(ovalIn: NSRect(x: 1050, y: 420, width: 100, height: 30)).fill()
        NSColor(calibratedRed: 0.94, green: 0.80, blue: 0.55, alpha: 0.62).setFill()
        NSRect(x: 520, y: 255, width: 170, height: 78).fill()
    }

    private static func drawSchoolServerRoom(size: NSSize) {
        NSColor.black.withAlphaComponent(0.48).setFill()
        for index in 0..<7 {
            let x = 180 + CGFloat(index) * 160
            NSBezierPath(roundedRect: NSRect(x: x, y: 180, width: 110, height: 560), xRadius: 12, yRadius: 12).fill()
            NSColor.systemBlue.withAlphaComponent(0.50).setFill()
            for light in 0..<8 {
                NSRect(x: x + 28, y: 260 + CGFloat(light) * 52, width: 54, height: 8).fill()
            }
        }
        NSColor.systemRed.withAlphaComponent(0.36).setFill()
        NSRect(x: 720, y: 610, width: 150, height: 42).fill()
    }

    private static func drawHospitalRooftop(size: NSSize) {
        NSColor.white.withAlphaComponent(0.22).setStroke()
        let pad = NSBezierPath(ovalIn: NSRect(x: 500, y: 230, width: 520, height: 280))
        pad.lineWidth = 5
        pad.stroke()
        NSColor.white.withAlphaComponent(0.32).setFill()
        NSRect(x: 0, y: 560, width: size.width, height: 30).fill()
        NSColor.systemRed.withAlphaComponent(0.22).setFill()
        NSBezierPath(ovalIn: NSRect(x: 680, y: 180, width: 360, height: 80)).fill()
    }

    private static func drawArchiveBasement(size: NSSize) {
        for index in 0..<8 {
            let x = 110 + CGFloat(index) * 170
            NSColor(calibratedWhite: 0.65, alpha: 0.14).setFill()
            NSRect(x: x, y: 170, width: 110, height: 560).fill()
            NSColor.white.withAlphaComponent(0.18).setStroke()
            for drawer in 0..<7 {
                NSBezierPath(rect: NSRect(x: x + 8, y: 205 + CGFloat(drawer) * 68, width: 94, height: 42)).stroke()
            }
        }
        NSColor.systemCyan.withAlphaComponent(0.24).setFill()
        NSBezierPath(ovalIn: NSRect(x: 600, y: 380, width: 320, height: 160)).fill()
    }

    private static func drawMirrorBridge(size: NSSize) {
        NSColor.white.withAlphaComponent(0.16).setFill()
        for index in 0..<6 {
            let x = 150 + CGFloat(index) * 210
            NSBezierPath(roundedRect: NSRect(x: x, y: 170, width: 150, height: 590), xRadius: 18, yRadius: 18).fill()
        }
        NSColor.systemRed.withAlphaComponent(0.34).setStroke()
        let doubled = NSBezierPath()
        doubled.lineWidth = 5
        doubled.move(to: CGPoint(x: 420, y: 260))
        doubled.curve(to: CGPoint(x: 1040, y: 620), controlPoint1: CGPoint(x: 560, y: 760), controlPoint2: CGPoint(x: 850, y: 90))
        doubled.stroke()
    }

    private static func drawReservoirGate(size: NSSize) {
        NSColor.black.withAlphaComponent(0.42).setFill()
        NSRect(x: 0, y: 480, width: size.width, height: 260).fill()
        NSColor.systemCyan.withAlphaComponent(0.36).setFill()
        NSBezierPath(roundedRect: NSRect(x: 0, y: 120, width: size.width, height: 260), xRadius: 80, yRadius: 80).fill()
        NSColor.systemRed.withAlphaComponent(0.58).setFill()
        for index in 0..<5 {
            NSBezierPath(ovalIn: NSRect(x: 520 + CGFloat(index) * 90, y: 620, width: 42, height: 42)).fill()
        }
    }

    private static func drawDawnBusLoop(size: NSSize) {
        NSColor.black.withAlphaComponent(0.45).setFill()
        NSBezierPath(roundedRect: NSRect(x: 240, y: 180, width: 1030, height: 520), xRadius: 46, yRadius: 46).fill()
        NSColor.white.withAlphaComponent(0.18).setFill()
        for index in 0..<5 {
            NSBezierPath(roundedRect: NSRect(x: 330 + CGFloat(index) * 170, y: 440, width: 120, height: 150), xRadius: 18, yRadius: 18).fill()
        }
        NSColor.systemRed.withAlphaComponent(0.42).setStroke()
        let cord = NSBezierPath()
        cord.lineWidth = 6
        cord.move(to: CGPoint(x: 340, y: 625))
        cord.line(to: CGPoint(x: 1120, y: 625))
        cord.stroke()
    }

    private static func drawSeaWallMural(size: NSSize) {
        NSColor.black.withAlphaComponent(0.34).setFill()
        NSRect(x: 0, y: 130, width: size.width, height: 260).fill()
        NSColor.white.withAlphaComponent(0.20).setStroke()
        for index in 0..<10 {
            let x = 80 + CGFloat(index) * 150
            NSBezierPath(rect: NSRect(x: x, y: 255, width: 118, height: 88)).stroke()
        }
        NSColor.systemRed.withAlphaComponent(0.64).setStroke()
        let umbrella = NSBezierPath()
        umbrella.lineWidth = 8
        umbrella.move(to: CGPoint(x: 570, y: 575))
        umbrella.curve(to: CGPoint(x: 930, y: 575), controlPoint1: CGPoint(x: 650, y: 735), controlPoint2: CGPoint(x: 850, y: 735))
        umbrella.line(to: CGPoint(x: 750, y: 295))
        umbrella.stroke()
        NSColor.systemCyan.withAlphaComponent(0.22).setFill()
        NSBezierPath(ovalIn: NSRect(x: 160, y: 135, width: 1180, height: 82)).fill()
    }

    private static func drawMaintenanceElevator(size: NSSize) {
        NSColor.black.withAlphaComponent(0.46).setFill()
        NSBezierPath(roundedRect: NSRect(x: 460, y: 145, width: 620, height: 660), xRadius: 18, yRadius: 18).fill()
        NSColor.white.withAlphaComponent(0.20).setStroke()
        let seam = NSBezierPath()
        seam.lineWidth = 4
        seam.move(to: CGPoint(x: 770, y: 165))
        seam.line(to: CGPoint(x: 770, y: 785))
        seam.stroke()
        NSColor.systemRed.withAlphaComponent(0.60).setFill()
        NSBezierPath(ovalIn: NSRect(x: 1015, y: 500, width: 54, height: 54)).fill()
        NSColor.systemBlue.withAlphaComponent(0.42).setFill()
        for index in 0..<4 {
            NSRect(x: 535 + CGFloat(index) * 108, y: 735, width: 72, height: 22).fill()
        }
    }

    private static func drawRainClinicRecords(size: NSSize) {
        NSColor.white.withAlphaComponent(0.22).setFill()
        for index in 0..<6 {
            let x = 130 + CGFloat(index) * 205
            NSBezierPath(roundedRect: NSRect(x: x, y: 195, width: 142, height: 485), xRadius: 12, yRadius: 12).fill()
            NSColor.black.withAlphaComponent(0.20).setFill()
            for drawer in 0..<5 {
                NSRect(x: x + 20, y: 245 + CGFloat(drawer) * 76, width: 102, height: 12).fill()
            }
        }
        NSColor.systemPink.withAlphaComponent(0.38).setStroke()
        let pulse = NSBezierPath()
        pulse.lineWidth = 6
        pulse.move(to: CGPoint(x: 490, y: 595))
        pulse.line(to: CGPoint(x: 570, y: 595))
        pulse.line(to: CGPoint(x: 610, y: 675))
        pulse.line(to: CGPoint(x: 655, y: 515))
        pulse.line(to: CGPoint(x: 705, y: 595))
        pulse.line(to: CGPoint(x: 1040, y: 595))
        pulse.stroke()
    }

    private static func drawWeatherControlRoom(size: NSSize) {
        NSColor.black.withAlphaComponent(0.52).setFill()
        NSBezierPath(roundedRect: NSRect(x: 190, y: 175, width: 1120, height: 570), xRadius: 26, yRadius: 26).fill()
        NSColor.systemCyan.withAlphaComponent(0.30).setStroke()
        for index in 0..<4 {
            let rect = NSRect(x: 315 + CGFloat(index) * 185, y: 380 - CGFloat(index % 2) * 45, width: 230, height: 230)
            let radar = NSBezierPath(ovalIn: rect)
            radar.lineWidth = 4
            radar.stroke()
        }
        NSColor.systemRed.withAlphaComponent(0.62).setFill()
        for index in 0..<7 {
            NSRect(x: 430 + CGFloat(index) * 92, y: 250, width: 36, height: CGFloat(80 + index * 20)).fill()
        }
    }

    private static func drawFerryPier(size: NSSize) {
        NSColor.black.withAlphaComponent(0.45).setFill()
        NSBezierPath(ovalIn: NSRect(x: -80, y: 115, width: size.width + 160, height: 260)).fill()
        NSColor(calibratedRed: 0.44, green: 0.24, blue: 0.12, alpha: 0.55).setFill()
        for index in 0..<9 {
            NSRect(x: 120 + CGFloat(index) * 150, y: 290, width: 115, height: 34).fill()
            NSRect(x: 155 + CGFloat(index) * 150, y: 160, width: 30, height: 225).fill()
        }
        NSColor.white.withAlphaComponent(0.18).setFill()
        NSBezierPath(roundedRect: NSRect(x: 940, y: 405, width: 290, height: 125), xRadius: 32, yRadius: 32).fill()
        NSColor.systemRed.withAlphaComponent(0.62).setStroke()
        let rope = NSBezierPath()
        rope.lineWidth = 6
        rope.move(to: CGPoint(x: 250, y: 560))
        rope.curve(to: CGPoint(x: 1240, y: 535), controlPoint1: CGPoint(x: 530, y: 470), controlPoint2: CGPoint(x: 900, y: 640))
        rope.stroke()
    }

    private static func drawFloodSirenTower(size: NSSize) {
        NSColor.black.withAlphaComponent(0.48).setFill()
        NSRect(x: 705, y: 145, width: 70, height: 590).fill()
        NSColor.white.withAlphaComponent(0.20).setStroke()
        for index in 0..<9 {
            let y = 190 + CGFloat(index) * 58
            let step = NSBezierPath()
            step.lineWidth = 3
            step.move(to: CGPoint(x: 620, y: y))
            step.line(to: CGPoint(x: 860, y: y + 40))
            step.stroke()
        }
        NSColor.systemRed.withAlphaComponent(0.76).setFill()
        NSBezierPath(ovalIn: NSRect(x: 650, y: 705, width: 180, height: 72)).fill()
        NSColor.systemRed.withAlphaComponent(0.26).setStroke()
        for index in 0..<3 {
            let wave = NSBezierPath(ovalIn: NSRect(x: 580 - CGFloat(index) * 55, y: 665 - CGFloat(index) * 35, width: 320 + CGFloat(index) * 110, height: 150 + CGFloat(index) * 70))
            wave.lineWidth = 4
            wave.stroke()
        }
    }

    private static func drawWeekendStationClock(size: NSSize) {
        NSColor.black.withAlphaComponent(0.38).setFill()
        NSRect(x: 0, y: 160, width: size.width, height: 170).fill()
        NSColor.white.withAlphaComponent(0.28).setStroke()
        let clockRect = NSRect(x: 610, y: 485, width: 280, height: 280)
        let clock = NSBezierPath(ovalIn: clockRect)
        clock.lineWidth = 6
        clock.stroke()
        let hour = NSBezierPath()
        hour.lineWidth = 7
        hour.move(to: CGPoint(x: clockRect.midX, y: clockRect.midY))
        hour.line(to: CGPoint(x: clockRect.midX - 80, y: clockRect.midY + 70))
        hour.move(to: CGPoint(x: clockRect.midX, y: clockRect.midY))
        hour.line(to: CGPoint(x: clockRect.midX + 105, y: clockRect.midY + 20))
        hour.stroke()
        NSColor.systemRed.withAlphaComponent(0.48).setFill()
        for index in 0..<5 {
            NSBezierPath(ovalIn: NSRect(x: 360 + CGFloat(index) * 165, y: 235, width: 96, height: 26)).fill()
        }
    }

    private static func drawCityStreet(size: NSSize) {
        NSColor.systemCyan.withAlphaComponent(0.22).setFill()
        NSRect(x: 1040, y: 220, width: 260, height: 310).fill()
        NSColor.systemRed.withAlphaComponent(0.18).setFill()
        NSRect(x: 280, y: 180, width: 180, height: 420).fill()
    }

    private static func cgAccent(for id: String) -> NSColor {
        if id.contains("airi") { return .systemOrange }
        if id.contains("yuka") || id.contains("archive") { return .systemBlue }
        if id.contains("ghost") || id.contains("lab") || id.contains("aquarium") || id.contains("greenhouse") { return .systemCyan }
        if id.contains("stationery") || id.contains("ink") || id.contains("teahouse") { return .systemOrange }
        if id.contains("clock") { return .systemYellow }
        if id.contains("mural") { return .systemGreen }
        if id.contains("elevator") { return .systemGray }
        if id.contains("clinic") { return .systemPink }
        if id.contains("weather") || id.contains("evidence") { return .systemBlue }
        if id.contains("ferry") { return .systemOrange }
        if id.contains("siren") { return .systemRed }
        if id.contains("cassette") { return .systemPurple }
        if id.contains("skybridge") || id.contains("crosswalk") { return .systemRed }
        if id.contains("museum") || id.contains("purification") { return .systemCyan }
        if id.contains("phone") { return .systemPink }
        if id.contains("tram") || id.contains("bus") { return .systemOrange }
        if id.contains("server") { return .systemBlue }
        if id.contains("hospital") { return .systemPink }
        if id.contains("reservoir") { return .systemCyan }
        if id.contains("bridge") { return .systemPurple }
        if id.contains("umbrella") { return .systemRed }
        if id.contains("laundromat") { return .systemCyan }
        if id.contains("deck") || id.contains("map") { return .systemBlue }
        if id.contains("tunnel") { return .systemCyan }
        if id.contains("radio") { return .systemBlue }
        if id.contains("infirmary") { return .systemPink }
        if id.contains("photo") { return .systemPurple }
        if id.contains("threshold") { return .systemOrange }
        if id.contains("shadow") || id.contains("abyss") { return .systemRed }
        if id.contains("rainbow") { return .systemPurple }
        return .systemRed
    }

    private static func drawCGSymbol(for id: String, size: NSSize, accent: NSColor) {
        accent.withAlphaComponent(0.84).setStroke()
        let symbolRect = NSRect(x: size.width * 0.43, y: size.height * 0.38, width: 210, height: 210)
        let path = NSBezierPath(ovalIn: symbolRect)
        path.lineWidth = 8
        path.stroke()

        if id.contains("letter") || id.contains("notebook") {
            NSColor.white.withAlphaComponent(0.46).setStroke()
            for index in 0..<7 {
                let y = symbolRect.minY + CGFloat(index) * 24 + 30
                let line = NSBezierPath()
                line.lineWidth = 2
                line.move(to: CGPoint(x: symbolRect.minX - 150, y: y))
                line.line(to: CGPoint(x: symbolRect.maxX + 150, y: y + CGFloat(index % 2) * 8))
                line.stroke()
            }
        } else if id.contains("mural") {
            NSColor.white.withAlphaComponent(0.34).setStroke()
            for row in 0..<3 {
                for column in 0..<5 {
                    NSBezierPath(rect: NSRect(x: symbolRect.minX - 150 + CGFloat(column) * 92, y: symbolRect.minY - 45 + CGFloat(row) * 62, width: 78, height: 46)).stroke()
                }
            }
            accent.withAlphaComponent(0.72).setStroke()
            let umbrella = NSBezierPath()
            umbrella.lineWidth = 7
            umbrella.move(to: CGPoint(x: symbolRect.midX - 120, y: symbolRect.midY + 38))
            umbrella.curve(to: CGPoint(x: symbolRect.midX + 120, y: symbolRect.midY + 38), controlPoint1: CGPoint(x: symbolRect.midX - 60, y: symbolRect.midY + 120), controlPoint2: CGPoint(x: symbolRect.midX + 60, y: symbolRect.midY + 120))
            umbrella.stroke()
        } else if id.contains("elevator") {
            NSColor.white.withAlphaComponent(0.42).setStroke()
            NSBezierPath(roundedRect: symbolRect.insetBy(dx: -60, dy: -60), xRadius: 12, yRadius: 12).stroke()
            let seam = NSBezierPath()
            seam.lineWidth = 5
            seam.move(to: CGPoint(x: symbolRect.midX, y: symbolRect.minY - 60))
            seam.line(to: CGPoint(x: symbolRect.midX, y: symbolRect.maxY + 60))
            seam.stroke()
            accent.withAlphaComponent(0.78).setFill()
            NSBezierPath(ovalIn: NSRect(x: symbolRect.maxX + 50, y: symbolRect.midY - 22, width: 44, height: 44)).fill()
        } else if id.contains("clinic") {
            NSColor.white.withAlphaComponent(0.46).setStroke()
            let pulse = NSBezierPath()
            pulse.lineWidth = 6
            pulse.move(to: CGPoint(x: symbolRect.minX - 170, y: symbolRect.midY))
            pulse.line(to: CGPoint(x: symbolRect.minX - 60, y: symbolRect.midY))
            pulse.line(to: CGPoint(x: symbolRect.minX - 12, y: symbolRect.midY + 80))
            pulse.line(to: CGPoint(x: symbolRect.midX + 25, y: symbolRect.midY - 95))
            pulse.line(to: CGPoint(x: symbolRect.midX + 88, y: symbolRect.midY))
            pulse.line(to: CGPoint(x: symbolRect.maxX + 170, y: symbolRect.midY))
            pulse.stroke()
        } else if id.contains("weather") || id.contains("evidence") {
            NSColor.white.withAlphaComponent(0.38).setStroke()
            for index in 0..<3 {
                let radar = NSBezierPath(ovalIn: symbolRect.insetBy(dx: CGFloat(index) * 34 - 50, dy: CGFloat(index) * 34 - 50))
                radar.lineWidth = 4
                radar.stroke()
            }
            accent.withAlphaComponent(0.70).setFill()
            for index in 0..<5 {
                NSRect(x: symbolRect.minX - 120 + CGFloat(index) * 76, y: symbolRect.minY - 70, width: 34, height: CGFloat(70 + index * 24)).fill()
            }
        } else if id.contains("ferry") {
            NSColor.white.withAlphaComponent(0.42).setFill()
            NSBezierPath(roundedRect: NSRect(x: symbolRect.minX - 150, y: symbolRect.midY - 35, width: 500, height: 90), xRadius: 34, yRadius: 34).fill()
            accent.withAlphaComponent(0.58).setStroke()
            let rope = NSBezierPath()
            rope.lineWidth = 7
            rope.move(to: CGPoint(x: symbolRect.minX - 160, y: symbolRect.maxY + 72))
            rope.curve(to: CGPoint(x: symbolRect.maxX + 150, y: symbolRect.maxY + 42), controlPoint1: CGPoint(x: symbolRect.minX, y: symbolRect.maxY - 12), controlPoint2: CGPoint(x: symbolRect.maxX, y: symbolRect.maxY + 128))
            rope.stroke()
        } else if id.contains("siren") {
            accent.withAlphaComponent(0.82).setFill()
            NSBezierPath(ovalIn: NSRect(x: symbolRect.midX - 80, y: symbolRect.maxY + 20, width: 160, height: 70)).fill()
            NSColor.white.withAlphaComponent(0.38).setStroke()
            for index in 0..<3 {
                let wave = NSBezierPath(ovalIn: NSRect(x: symbolRect.midX - 150 - CGFloat(index) * 50, y: symbolRect.midY - 35 - CGFloat(index) * 28, width: 300 + CGFloat(index) * 100, height: 110 + CGFloat(index) * 56))
                wave.lineWidth = 4
                wave.stroke()
            }
        } else if id.contains("umbrella") || id.contains("shrine") {
            let umbrella = NSBezierPath()
            umbrella.lineWidth = 7
            umbrella.move(to: CGPoint(x: symbolRect.midX - 140, y: symbolRect.midY + 40))
            umbrella.curve(to: CGPoint(x: symbolRect.midX + 140, y: symbolRect.midY + 40), controlPoint1: CGPoint(x: symbolRect.midX - 70, y: symbolRect.midY + 130), controlPoint2: CGPoint(x: symbolRect.midX + 70, y: symbolRect.midY + 130))
            umbrella.stroke()
        } else if id.contains("radio") || id.contains("pulse") {
            NSColor.white.withAlphaComponent(0.46).setStroke()
            let wave = NSBezierPath()
            wave.lineWidth = 5
            wave.move(to: CGPoint(x: symbolRect.minX - 170, y: symbolRect.midY))
            for index in 0..<12 {
                let x = symbolRect.minX - 170 + CGFloat(index) * 46
                let y = symbolRect.midY + CGFloat(index % 2 == 0 ? 64 : -58)
                wave.line(to: CGPoint(x: x, y: y))
            }
            wave.line(to: CGPoint(x: symbolRect.maxX + 170, y: symbolRect.midY))
            wave.stroke()
        } else if id.contains("photo") {
            NSColor.white.withAlphaComponent(0.64).setFill()
            for index in 0..<4 {
                NSBezierPath(roundedRect: NSRect(x: symbolRect.minX - 70 + CGFloat(index) * 90, y: symbolRect.minY - 35, width: 66, height: 96), xRadius: 8, yRadius: 8).fill()
            }
        } else if id.contains("greenhouse") {
            NSColor.white.withAlphaComponent(0.42).setStroke()
            for index in 0..<5 {
                let stem = NSBezierPath()
                stem.lineWidth = 4
                let x = symbolRect.minX - 90 + CGFloat(index) * 88
                stem.move(to: CGPoint(x: x, y: symbolRect.minY - 60))
                stem.curve(to: CGPoint(x: x + 70, y: symbolRect.maxY + 40), controlPoint1: CGPoint(x: x - 50, y: symbolRect.midY), controlPoint2: CGPoint(x: x + 120, y: symbolRect.midY))
                stem.stroke()
            }
        } else if id.contains("threshold") {
            NSColor.white.withAlphaComponent(0.48).setFill()
            NSBezierPath(roundedRect: NSRect(x: symbolRect.minX - 25, y: symbolRect.minY - 40, width: 115, height: 285), xRadius: 10, yRadius: 10).fill()
            NSColor.black.withAlphaComponent(0.42).setFill()
            NSBezierPath(roundedRect: NSRect(x: symbolRect.midX + 4, y: symbolRect.minY - 20, width: 105, height: 250), xRadius: 8, yRadius: 8).fill()
        } else if id.contains("clock") {
            NSColor.white.withAlphaComponent(0.48).setStroke()
            NSBezierPath(ovalIn: symbolRect.insetBy(dx: -24, dy: -24)).stroke()
            let hand = NSBezierPath()
            hand.lineWidth = 6
            hand.move(to: CGPoint(x: symbolRect.midX, y: symbolRect.midY))
            hand.line(to: CGPoint(x: symbolRect.midX, y: symbolRect.maxY + 82))
            hand.move(to: CGPoint(x: symbolRect.midX, y: symbolRect.midY))
            hand.line(to: CGPoint(x: symbolRect.maxX + 55, y: symbolRect.midY + 35))
            hand.stroke()
        } else if id.contains("cassette") {
            NSColor.white.withAlphaComponent(0.48).setStroke()
            NSBezierPath(roundedRect: symbolRect.insetBy(dx: -70, dy: 22), xRadius: 18, yRadius: 18).stroke()
            NSBezierPath(ovalIn: NSRect(x: symbolRect.minX - 10, y: symbolRect.midY - 28, width: 56, height: 56)).stroke()
            NSBezierPath(ovalIn: NSRect(x: symbolRect.maxX - 46, y: symbolRect.midY - 28, width: 56, height: 56)).stroke()
        } else if id.contains("crosswalk") || id.contains("skybridge") {
            NSColor.white.withAlphaComponent(0.46).setFill()
            for index in 0..<5 {
                NSRect(x: symbolRect.minX - 120 + CGFloat(index) * 88, y: symbolRect.midY - 20, width: 58, height: 20).fill()
            }
            accent.withAlphaComponent(0.58).setFill()
            NSBezierPath(ovalIn: NSRect(x: symbolRect.midX - 32, y: symbolRect.maxY + 42, width: 64, height: 64)).fill()
        } else if id.contains("phone") {
            NSColor.white.withAlphaComponent(0.46).setStroke()
            NSBezierPath(roundedRect: NSRect(x: symbolRect.midX - 74, y: symbolRect.minY - 35, width: 148, height: 270), xRadius: 18, yRadius: 18).stroke()
            let cord = NSBezierPath()
            cord.lineWidth = 5
            cord.move(to: CGPoint(x: symbolRect.midX - 35, y: symbolRect.midY + 10))
            cord.curve(to: CGPoint(x: symbolRect.midX + 78, y: symbolRect.minY - 45), controlPoint1: CGPoint(x: symbolRect.midX - 110, y: symbolRect.minY), controlPoint2: CGPoint(x: symbolRect.midX + 135, y: symbolRect.midY))
            cord.stroke()
        } else if id.contains("museum") || id.contains("purification") {
            NSColor.white.withAlphaComponent(0.42).setStroke()
            for index in 0..<4 {
                let x = symbolRect.minX - 75 + CGFloat(index) * 95
                let column = NSBezierPath()
                column.lineWidth = 6
                column.move(to: CGPoint(x: x, y: symbolRect.minY - 70))
                column.line(to: CGPoint(x: x, y: symbolRect.maxY + 100))
                column.stroke()
            }
        } else if id.contains("umbrella") {
            let umbrella = NSBezierPath()
            umbrella.lineWidth = 8
            umbrella.move(to: CGPoint(x: symbolRect.midX - 150, y: symbolRect.midY + 35))
            umbrella.curve(to: CGPoint(x: symbolRect.midX + 150, y: symbolRect.midY + 35), controlPoint1: CGPoint(x: symbolRect.midX - 70, y: symbolRect.midY + 140), controlPoint2: CGPoint(x: symbolRect.midX + 70, y: symbolRect.midY + 140))
            umbrella.line(to: CGPoint(x: symbolRect.midX, y: symbolRect.minY - 90))
            umbrella.stroke()
        } else if id.contains("laundromat") {
            NSColor.white.withAlphaComponent(0.44).setStroke()
            NSBezierPath(ovalIn: symbolRect.insetBy(dx: -20, dy: -20)).stroke()
            NSBezierPath(ovalIn: symbolRect.insetBy(dx: 42, dy: 42)).stroke()
        } else if id.contains("deck") || id.contains("map") || id.contains("tunnel") {
            NSColor.white.withAlphaComponent(0.44).setStroke()
            let route = NSBezierPath()
            route.lineWidth = 5
            route.move(to: CGPoint(x: symbolRect.minX - 160, y: symbolRect.midY - 60))
            route.curve(to: CGPoint(x: symbolRect.maxX + 150, y: symbolRect.midY + 78), controlPoint1: CGPoint(x: symbolRect.minX, y: symbolRect.maxY + 120), controlPoint2: CGPoint(x: symbolRect.maxX, y: symbolRect.minY - 120))
            route.stroke()
            for index in 0..<4 {
                NSBezierPath(ovalIn: NSRect(x: symbolRect.minX - 85 + CGFloat(index) * 105, y: symbolRect.midY - 18 + CGFloat(index % 2) * 40, width: 30, height: 30)).fill()
            }
        } else if id.contains("teahouse") {
            NSColor.white.withAlphaComponent(0.50).setStroke()
            for index in 0..<2 {
                NSBezierPath(ovalIn: NSRect(x: symbolRect.minX - 45 + CGFloat(index) * 140, y: symbolRect.midY - 24, width: 104, height: 62)).stroke()
            }
        } else {
            NSColor.white.withAlphaComponent(0.35).setFill()
            NSBezierPath(roundedRect: symbolRect.insetBy(dx: 62, dy: 28), xRadius: 18, yRadius: 18).fill()
        }
    }

    private static func drawEyes(centerX: CGFloat, y: CGFloat, color: NSColor) {
        color.setFill()
        NSBezierPath(ovalIn: NSRect(x: centerX - 54, y: y, width: 24, height: 14)).fill()
        NSBezierPath(ovalIn: NSRect(x: centerX + 30, y: y, width: 24, height: 14)).fill()
    }

    private static func drawAccent(for id: String, centerX: CGFloat, size: NSSize, color: NSColor) {
        color.withAlphaComponent(0.82).setFill()
        if id.contains("sea") {
            NSBezierPath(roundedRect: NSRect(x: centerX - 122, y: 496, width: 244, height: 18), xRadius: 8, yRadius: 8).fill()
            NSBezierPath(ovalIn: NSRect(x: centerX + 82, y: 698, width: 34, height: 34)).fill()
        } else if id.contains("yuka") {
            NSColor.white.withAlphaComponent(0.84).setStroke()
            NSBezierPath(ovalIn: NSRect(x: centerX - 62, y: 640, width: 48, height: 30)).stroke()
            NSBezierPath(ovalIn: NSRect(x: centerX + 14, y: 640, width: 48, height: 30)).stroke()
        } else if id.contains("airi") {
            NSColor(calibratedRed: 1.0, green: 0.76, blue: 0.22, alpha: 0.70).setFill()
            NSBezierPath(roundedRect: NSRect(x: centerX - 138, y: 502, width: 276, height: 30), xRadius: 14, yRadius: 14).fill()
        } else {
            NSBezierPath(roundedRect: NSRect(x: centerX - 82, y: 472, width: 164, height: 12), xRadius: 6, yRadius: 6).fill()
        }
    }

    private static func drawUmbrella(centerX: CGFloat, size: NSSize) {
        NSColor.black.withAlphaComponent(0.92).setFill()
        let umbrella = NSBezierPath()
        umbrella.move(to: CGPoint(x: centerX - 230, y: 815))
        umbrella.curve(to: CGPoint(x: centerX + 230, y: 815), controlPoint1: CGPoint(x: centerX - 96, y: 920), controlPoint2: CGPoint(x: centerX + 96, y: 920))
        umbrella.line(to: CGPoint(x: centerX + 185, y: 786))
        umbrella.line(to: CGPoint(x: centerX - 185, y: 786))
        umbrella.close()
        umbrella.fill()
    }
}
