//
//  UpdateElectricityMeterJob.swift
//  home-control-adapter-goe-wallbox
//
//  Created by Christoph Pageler on 16.11.24.
//

import Foundation
import GoeKit
import HomeControlKit
import HomeControlClient
import HomeControlLogging
import Logging

class UpdateElectricityMeterJob: Job {
    private let logger = Logger(homeControl: "adapter-goe-wallbox.update-inverter-reading-job")
    private var homeControlClient: HomeControlClient
    private let goeClient: GoeClient
    private let ccnCarName: String
    private let electricityMeterID: UUID

    init(
        homeControlClient: HomeControlClient,
        goeClient: GoeClient,
        ccnCarName: String,
        electricityMeterID: UUID
    ) {
        self.homeControlClient = homeControlClient
        self.goeClient = goeClient
        self.ccnCarName = ccnCarName
        self.electricityMeterID = electricityMeterID

        super.init(maxAge: 2)
    }

    override func run() async {
        do {
            try await runCatch()
        } catch {
            logger.critical("Failed run \(error)")
        }
    }

    private func runCatch() async throws {
        let response = await self.goeClient.status(filter: "ccn,ccp")

        let carPower: Double
        if let index = response?.ccn?.firstIndex(of: ccnCarName) {
            carPower = response?.ccp?[index] ?? 0
        } else {
            logger.warning("Could not find \"\(ccnCarName)\" in status")
            return
        }
        logger.info("Car Power: \(carPower)")

        let electricityMeterReading = ElectricityMeterReading(readingAt: Date(), power: carPower)
        let stored = try await homeControlClient.electricityMeter
            .readings(id: electricityMeterID)
            .create(electricityMeterReading)

        logger.info("Stored electricity meter reading: \(stored.id)")
    }
}
