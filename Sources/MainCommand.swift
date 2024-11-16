//
//  MainCommand.swift
//  home-control-adapter-sungrow-inverter
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
import SungrowKit

@main
struct MainCommand: AsyncParsableCommand {
    private static let logger = Logger(homeControl: "adapter-goe-wallbox.main-command")

    func run() async throws {
        LoggingSystem.bootstrapHomeControl()

        // Load environment from .env.json
        let dotEnv = try DotEnv.fromWorkingDirectory()

        // Prepare home control client
        var homeControlClient = HomeControlClient.localhost
        homeControlClient.authToken = try dotEnv.require("AUTH_TOKEN")

        let goeAddress = try dotEnv.require("GOE_ADDRESS")
        guard let goeClient = GoeClient(address: goeAddress) else {
            Self.logger.critical("Failed to initialize GoeClient with address \(goeAddress)")
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
                goeClient: goeClient,
                ccnCarName: ccnCarName,
                electricityMeterID: electricityMeterIDUUID
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
