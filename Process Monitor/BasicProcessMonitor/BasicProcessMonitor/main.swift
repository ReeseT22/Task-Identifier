//
//  main.swift
//  BasicProcessMonitor
//
//  Created by Reese Turley on 3/18/25.
//

import Foundation
import AppKit

// Dictionary to track existing processes
var knownProcesses = Set<Int32>()

// Function to get a list of running processes
func getRunningProcesses() -> [ProcessInfo] {
    var processes = [ProcessInfo]()
    
    let task = Process()
    task.launchPath = "/bin/ps"
    task.arguments = ["-axo", "pid,ppid,command"]

    let outputPipe = Pipe()
    task.standardOutput = outputPipe
    task.launch()
    
    let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
    if let output = String(data: data, encoding: .utf8) {
        let lines = output.split(separator: "\n").dropFirst() // Skip header
        
        for line in lines {
            let components = line.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
            if components.count == 3,
               let pid = Int32(components[0]),
               let ppid = Int32(components[1]) {
                let command = String(components[2])
                processes.append(ProcessInfo(pid: pid, ppid: ppid, command: command))
            }
        }
    }
    
    return processes
}

// Struct to store process details
struct ProcessInfo {
    let pid: Int32
    let ppid: Int32
    let command: String
}



var seenProcesses: Set<pid_t> = Set()

func monitorProcesses() {
    while true {
        let process = Process()
        process.launchPath = "/bin/ps"
        process.arguments = ["-axo", "pid,command"]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.launch()

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            let lines = output.split(separator: "\n").dropFirst()

            for line in lines {
                let columns = line.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                if columns.count == 2, let pid = Int32(columns[0]) {
                    let command = String(columns[1])

                    if !seenProcesses.contains(pid) {
                        seenProcesses.insert(pid)
                        print("🚨 A New Process Has Been Detected: \(command) (PID: \(pid))")
                    }
                }
            }
        }

        usleep(500_000)  // Sleep for 0.5 seconds
    }
}

// Run the monitor
DispatchQueue.global(qos: .background).async {
    monitorProcesses()
}

// Keep the script alive
RunLoop.main.run()

