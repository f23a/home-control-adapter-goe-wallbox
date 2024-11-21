//
//  MainCommand.swift
//  home-control-adapter-goe-wallbox
//
//  Created by Christoph Pageler on 31.10.24.
//

import ArgumentParser
import Foundation
import GoeKit
import HomeControlClient
import HomeControlKit
import HomeControlLogging
import Logging

@main
struct MainCommand: AsyncParsableCommand {
    private static let logger = Logger(homeControl: "adapter-goe-wallbox.main-command")

    func run() async throws {
        LoggingSystem.bootstrapHomeControl()

        // Load environment from .env.json
        let dotEnv = try DotEnv<[String: String]>.fromWorkingDirectory()

        // Prepare home control client
        var homeControlClient = HomeControlClient.localhost
        homeControlClient.authToken = try dotEnv.require("AUTH_TOKEN")

        // Prepare go-e controller client
        let goeControllerAddress = try dotEnv.require("GOE_CONTROLLER_ADDRESS")
        guard let goeControllerClient = GoeClient(address: goeControllerAddress) else {
            Self.logger.critical("Failed to initialize goe controller client with address \(goeControllerAddress)")
            return
        }

        // Prepare go-e charger client
        let goeChargerAddress = try dotEnv.require("GOE_CHARGER_ADDRESS")
        guard let goeChargerClient = GoeClient(address: goeChargerAddress) else {
            Self.logger.critical("Failed to initialize goe charger client with address \(goeChargerAddress)")
            return
        }

        let ccnCarName = try dotEnv.require("CCN_CAR_NAME")
        let electricityMeterID = try dotEnv.require("ELECTRICITY_METER_ID_CAR")
        guard let electricityMeterIDUUID = UUID(uuidString: electricityMeterID) else {
            Self.logger.critical("ELECTRICITY_METER_ID_CAR \"\(electricityMeterID)\" is not an uuid")
            return
        }

        // Prepare jobs
        let jobs: [Job] = [
            UpdateElectricityMeterJob(
                homeControlClient: homeControlClient,
                goeClient: goeControllerClient,
                ccnCarName: ccnCarName,
                electricityMeterID: electricityMeterIDUUID
            ),
            EcomaticJob(
                homeControlClient: homeControlClient,
                goeClient: goeChargerClient
            )
        ]

        // run jobs until command is canceled using ctrl + c
        while true {
            for job in jobs {
                await job.runIfNeeded(at: Date())
            }
            await Task.sleep(1.seconds)
        }
    }
}
