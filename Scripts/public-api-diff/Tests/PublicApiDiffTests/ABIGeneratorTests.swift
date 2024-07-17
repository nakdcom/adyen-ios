//
//  File.swift
//  
//
//  Created by Alexander Guretzki on 12/07/2024.
//

@testable import public_api_diff
import XCTest

class ABIGeneratorTests: XCTestCase {
    
    func test_noSchemeProvided_shouldHandleAsPackage() throws {
        
        let shell = MockShell()
        let xcodeTools = XcodeTools(shell: shell)
        
        var fileHandler = MockFileHandler()
        fileHandler.handleFileExists = { _ in
            return true
        }
        fileHandler.handleLoadData = { _ in
            try XCTUnwrap("".data(using: .utf8))
        }
        
        var logger = MockLogger()
        logger.handleLog = { message, subsystem in
            XCTAssertEqual(message, "📋 Generating ABI files for `projectDir`")
            XCTAssertEqual(subsystem, "PackageABIGenerator")
        }
        
        let abiGenerator = ABIGenerator(
            xcodeTools: xcodeTools,
            fileHandler: fileHandler,
            logger: logger
        )
        
        let output = try abiGenerator.generate(for: URL(filePath: "projectDir"), scheme: nil)
        let expectedOutput = [ABIGeneratorOutput]()
        XCTAssertEqual(output, expectedOutput)
    }
    
    func test_schemeProvided_shouldHandleAsProject() throws {
        
        let shell = MockShell()
        let xcodeTools = XcodeTools(shell: shell)
        
        var fileHandler = MockFileHandler()
        fileHandler.handleFileExists = { _ in
            return true
        }
        fileHandler.handleLoadData = { _ in
            try XCTUnwrap("".data(using: .utf8))
        }
        fileHandler.handleContentsOfDirectory = { _ in
            ["abi.json"]
        }
        
        var logger = MockLogger()
        logger.handleLog = { message, subsystem in
            XCTAssertEqual(message, "📋 Locating ABI file for `projectDir`")
            XCTAssertEqual(subsystem, "ProjectABIProvider")
        }
        logger.handleDebug = { message, subsystem in
            XCTAssertEqual(message, "- `abi.json`")
            XCTAssertEqual(subsystem, "ProjectABIProvider")
        }
        
        let abiGenerator = ABIGenerator(
            xcodeTools: xcodeTools,
            fileHandler: fileHandler,
            logger: logger
        )
        
        let scheme = "Scheme"
        
        let output = try abiGenerator.generate(for: URL(filePath: "projectDir"), scheme: scheme)
        let expectedOutput: [ABIGeneratorOutput] = [.init(
            targetName: "Scheme",
            abiJsonFileUrl: URL(filePath: "projectDir/.build/Build/Products/Debug-maccatalyst/\(scheme).framework/Modules/\(scheme).swiftmodule/abi.json")
        )]
        
        XCTAssertEqual(output, expectedOutput)
    }
}
