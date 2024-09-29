//
//  ContentView.swift
//  HomeControlAdapterSungrowInverter
//
//  Created by Christoph Pageler on 28.09.24.
//

import HomeControlKit
import SwiftUI

struct ContentView: View {
    @State private var viewModel = ContentViewModel()

    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Picker("Electricity Meter", selection: $viewModel.selectedElectricityMeter) {
                        ForEach(viewModel.electricityMeters) { electricityMeter in
                            Text(electricityMeter.meter.title)
                                .tag(electricityMeter as StoredElectricityMeter?)
                        }
                    }
                    Button(action: viewModel.updateElectricityMeters) {
                        Image(systemName: "arrow.counterclockwise")
                    }
                }
                Stepper(value: $viewModel.updateTimerInterval, in: 1...10, step: 1) {
                    HStack {
                        Text("Update Timer Interval")
                        Text("\(Int(viewModel.updateTimerInterval))").bold()
                    }
                }
                HStack {
                    Button("Start Update", action: viewModel.startTimer)
                        .disabled(viewModel.isTimerRunning)
                    Button("Stop Update", action: viewModel.stopTimer)
                        .disabled(!viewModel.isTimerRunning)
                }
            }
        }
        .padding()
        .onAppear {
            viewModel.updateElectricityMeters()
        }
    }
}

#Preview {
    ContentView()
}
