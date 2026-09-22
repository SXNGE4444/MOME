import XCTest
@testable import MOME

final class AdapterSafetyTests: XCTestCase {
    func testProjectDefinedCommandsRequireApproval() {
        let project = MOMEProject(
            name: "Untrusted Project",
            path: "/tmp/mome-untrusted-project",
            kind: .unknown,
            commands: [
                "custom": "echo changed > output.txt"
            ]
        )

        let custom = AdapterRegistry.actions(for: project).first { $0.title == "Custom" }

        XCTAssertNotNil(custom)
        XCTAssertEqual(custom?.risk, .write)
        XCTAssertEqual(custom?.risk.requiresApproval, true)
    }

    func testWriteReleaseAndDangerousActionsRequireApproval() {
        XCTAssertFalse(CommandRisk.read.requiresApproval)
        XCTAssertFalse(CommandRisk.safe.requiresApproval)
        XCTAssertTrue(CommandRisk.write.requiresApproval)
        XCTAssertTrue(CommandRisk.release.requiresApproval)
        XCTAssertTrue(CommandRisk.dangerous.requiresApproval)
    }
}
