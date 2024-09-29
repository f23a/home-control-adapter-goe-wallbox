//
//  ContentViewModel.swift
//  HomeControlAdapterSungrowInverter
//
//  Created by Christoph Pageler on 28.09.24.
//

import GoeKit
import HomeControlClient
import HomeControlKit
import SwiftUI

@Observable final class ContentViewModel {
    private var goeClient: GoeClient
    private var homeControlClient: HomeControlClient
    var selectedElectricityMeter: StoredElectricityMeter?
    private(set) var electricityMeters: [StoredElectricityMeter] = []

    init() {
        goeClient = GoeClient(address: "192.168.178.85")!
        homeControlClient = HomeControlClient.localhost
        homeControlClient.authToken = HomeControlKit.Environment.require("AUTH_TOKEN")
    }

    var updateTimerInterval: TimeInterval = 2.0 {
        didSet {
            refreshTimerIfNeeded()
        }
    }
    var isTimerRunning: Bool { updateTimer != nil }
    var updateTimer: Timer?

    func updateElectricityMeters() {
        Task {
            do {
                electricityMeters = try await homeControlClient.electricityMeter.index()
            } catch {
                electricityMeters = []
            }

        }
    }

    func startTimer() {
        stopTimer()
        updateTimer = .scheduledTimer(withTimeInterval: updateTimerInterval, repeats: true) { [weak self] _ in
            self?.fireTimer()
        }
    }

    func stopTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func refreshTimerIfNeeded() {
        guard isTimerRunning else { return }
        startTimer()
    }

    private func fireTimer() {
        guard let selectedElectricityMeter else {
            print("No Electricity Meter")
            return
        }
        print("Fire Timer \(Date())")
        Task {
            do {
                let response = await self.goeClient.status(filter: "ccn,ccp")

                let carPower: Double
                if let index = response?.ccn?.firstIndex(of: "Car") {
                    carPower = response?.ccp?[index] ?? 0
                } else {
                    print("Could not find \"Car\" in status")
                    return
                }
                print("Updated Car Power: \(carPower)")
                let electricityMeterReading = ElectricityMeterReading(readingAt: Date(), power: carPower)

                try await homeControlClient.electricityMeter.reading.create(
                    id: selectedElectricityMeter.id,
                    electricityMeterReading
                )
            } catch {
                print("Failed to create electricity meter reading: \(error)")
            }
        }
    }
}
