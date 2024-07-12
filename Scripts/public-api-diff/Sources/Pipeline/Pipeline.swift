//
//  File.swift
//  
//
//  Created by Alexander Guretzki on 11/07/2024.
//

import Foundation

struct Pipeline {
    
    let newProjectSource: ProjectSource
    let oldProjectSource: ProjectSource
    let scheme: String?
    
    let projectBuilder: any ProjectBuilding
    let abiGenerator: any ABIGenerating
    let libraryAnalyzer: any LibraryAnalyzing
    let sdkDumpGenerator: any SDKDumpGenerating
    let sdkDumpAnalyzer: any SDKDumpAnalyzing
    let outputGenerator: any OutputGenerating
    
    init(
        newProjectSource: ProjectSource,
        oldProjectSource: ProjectSource,
        scheme: String?,
        projectBuilder: any ProjectBuilding,
        abiGenerator: any ABIGenerating,
        libraryAnalyzer: any LibraryAnalyzing,
        sdkDumpGenerator: any SDKDumpGenerating,
        sdkDumpAnalyzer: any SDKDumpAnalyzing,
        outputGenerator: any OutputGenerating
    ) {
        self.newProjectSource = newProjectSource
        self.oldProjectSource = oldProjectSource
        self.scheme = scheme
        self.projectBuilder = projectBuilder
        self.abiGenerator = abiGenerator
        self.libraryAnalyzer = libraryAnalyzer
        self.sdkDumpGenerator = sdkDumpGenerator
        self.sdkDumpAnalyzer = sdkDumpAnalyzer
        self.outputGenerator = outputGenerator
    }
    
    func run() throws -> String {
        
        // Building both projects from the respective source
        let oldProjectUrl = try projectBuilder.build(source: oldProjectSource, scheme: scheme)
        let newProjectUrl = try projectBuilder.build(source: newProjectSource, scheme: scheme)
        
        // Generating abi files from the respective builds
        let oldAbiFiles = try abiGenerator.generate(for: oldProjectUrl, scheme: scheme)
        let newAbiFiles = try abiGenerator.generate(for: newProjectUrl, scheme: scheme)
        
        let allTargets = Set(oldAbiFiles.map(\.targetName)).union(Set(newAbiFiles.map(\.targetName)))
        if allTargets.isEmpty { throw PipelineError.noTargetFound }
        
        var changes = [String: [Change]]()
        
        // Analyzing if there are any changes in available libraries between the project versions
        let libraryChanges = try libraryAnalyzer.analyze(
            oldProjectUrl: oldProjectUrl,
            newProjectUrl: newProjectUrl
        )
        
        if !libraryChanges.isEmpty {
            changes[""] = libraryChanges
        }
        
        // Goes through all the available abi files and compares them
        try allTargets.forEach { target in
            guard let oldAbiJson = oldAbiFiles.abiJsonFileUrl(for: target) else {
                return changes[target] = [.removedTarget]
            }
            
            guard let newAbiJson = newAbiFiles.abiJsonFileUrl(for: target) else {
                return changes[target] = [.addedTarget]
            }
            
            // Generate SDKDump objects
            let oldSDKDump = try sdkDumpGenerator.generate(for: oldAbiJson)
            let newSDKDump = try sdkDumpGenerator.generate(for: newAbiJson)
            
            // Compare SDKDump objects
            let targetChanges = try sdkDumpAnalyzer.analyze(
                old: oldSDKDump,
                new: newSDKDump
            )
            
            if !targetChanges.isEmpty {
                changes[target] = targetChanges
            }
        }
        
        return try outputGenerator.generate(
            from: changes,
            allTargets: allTargets.sorted(),
            oldSource: oldProjectSource,
            newSource: newProjectSource
        )
    }
}

// MARK: - Convenience

private extension Change {
    
    static var removedTarget: Self {
        .init(changeType: .removal, parentName: "", changeDescription: "Target was removed")
    }
    
    static var addedTarget: Self {
        .init(changeType: .addition, parentName: "", changeDescription: "Target was added")
    }
}

private extension [String: [Change]] {
    
    mutating func append(change: Change, to moduleName: String) {
        self[moduleName] = (self[moduleName] ?? []) + [change]
    }
}

private extension [ABIGeneratorOutput] {
    
    func abiJsonFileUrl(for targetName: String) -> URL? {
        first { $0.targetName == targetName }?.abiJsonFileUrl
    }
}
