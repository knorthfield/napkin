import Foundation
import Testing
@testable import Napkin

@Test func theTestTargetRunsInTheApp() {
    #expect(Bundle.main.bundleIdentifier == "com.krisnorthfield.Napkin")
}
