//
//  EcomaticJob.swift
//  home-control-adapter-goe-wallbox
//
//  Created by Christoph Pageler on 20.11.24.
//

import Foundation
import GoeKit
import HomeControlKit
import HomeControlClient
import HomeControlLogging
import Logging

class EcomaticJob: Job {
    private let logger = Logger(homeControl: "adapter-goe-wallbox.ecomatic-job")
    private var homeControlClient: HomeControlClient
    private let goeClient: GoeClient

    init(
        homeControlClient: HomeControlClient,
        goeClient: GoeClient
    ) {
        self.homeControlClient = homeControlClient
        self.goeClient = goeClient

        super.init(maxAge: 3)
    }

    override func run() async {
        do {
            try await runCatch()
        } catch {
            logger.critical("Failed run \(error)")
        }
    }

    private func runCatch() async throws {
        let date = Date()
        let formattedDate = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)

        // Query for currently active force charging range that was sent to inverter
        let activeForceChargingRanges = try await homeControlClient.forceChargingRanges.active(
            at: date,
            additionalFilter: [
                .state(.sent),
            ],
            pagination: .init(page: 0, per: 1)
        )

        logger.info("Active force charging ranges \(activeForceChargingRanges.items.count)")
        guard let activeForceChargingRange = activeForceChargingRanges.items.first else {
            return
        }

        let formattedRange = activeForceChargingRange.value.dateRange.formatted()
        logger.info("Continue with \(activeForceChargingRange.id) \(formattedRange)")

        // Check if range just started or is about to end
        // if just started
        // - set logic mode to basic if needed
        // if is about to end
        // - set logic mote back to eco if needed

        let startingRange = activeForceChargingRange.value.startsAt.range(endsIn: 15.minutes)
        let formattedStartingRange = startingRange.formatted()
        let endsRange = activeForceChargingRange.value.endsAt.range(startedBefore: 15.minutes)
        let formattedEndsRange = endsRange.formatted()
        let isVehicleChargingAllowed = activeForceChargingRange.value.isVehicleChargingAllowed

        // When date is in starting range and vehicle charging is allowed, change to basic if needed
        if startingRange.contains(date) && isVehicleChargingAllowed {
            logger.info("In starting range \(formattedStartingRange), set to basic if needed")
            try await setLogicModeIfNeeded(logicMode: .basic)
        } else if endsRange.contains(date) {
            logger.info("In ending range \(formattedEndsRange), set to eco if needed")
            try await setLogicModeIfNeeded(logicMode: .eco)
        } else {
            logger.info("Date \(formattedDate) is neither in starting \(formattedStartingRange) nor ending range \(formattedEndsRange).")
        }
    }

    private func setLogicModeIfNeeded(logicMode: GoeLogicMode) async throws {
        let currentLogicMode = try await goeClient.logicMode()
        let updateNeeded = currentLogicMode != logicMode
        logger.info("Set logic mode to \(logicMode). Current logic mode \(currentLogicMode). Update needed \(updateNeeded)")
        guard updateNeeded else { return }

        let success = try await goeClient.setLogicMode(logicMode: logicMode)
        if success {
            logger.info("Successfully sent new logic mode")

            let message = Message(
                type: .wallboxEcomaticDidUpdateLogicMode,
                title: "Wallbox Mode Changed",
                body: "Modus geändert in: \(logicMode)"
            )
            let storedMessage = try await homeControlClient.messages.create(message)
            try await homeControlClient.messages.sendPushNotifications(id: storedMessage.id)

            logger.info("Sent message")
        } else {
            logger.critical("Failedt to send new logic mode")
        }
    }
}

extension Date {
    func range(endsIn: TimeInterval) -> Range<Date> {
        self..<self.addingTimeInterval(endsIn)
    }

    func range(startedBefore: TimeInterval) -> Range<Date> {
        self.addingTimeInterval(-startedBefore)..<self
    }
}
