// swift-tools-version:5.5
import PackageDescription


let package = Package(
	name: "GitHubBridge",
	platforms: [.iOS(.v13)],
	products: [.library(name: "GitHubBridge", targets: ["GitHubBridge"])],
	dependencies: [
		.package(url: "https://github.com/Frizlab/BMO.git",              branch: "main"),
		.package(url: "https://github.com/Frizlab/LinkHeaderParser.git", branch: "main"),
		.package(url: "https://github.com/Frizlab/UnwrapOrThrow.git",    from: "1.0.0"),
		.package(url: "https://github.com/iwill/generic-json-swift.git", from: "2.0.2")
	],
	targets: [
		.target(name: "GitHubBridge", dependencies: [
			.product(name: "BMOCoreData",      package: "BMO"),
			.product(name: "GenericJSON",      package: "generic-json-swift"),
			.product(name: "LinkHeaderParser", package: "LinkHeaderParser"),
			.product(name: "UnwrapOrThrow",    package: "UnwrapOrThrow")
		]/*, swiftSettings: [
			.unsafeFlags(["-Xfrontend", "-warn-concurrency", "-Xfrontend", "-enable-actor-data-race-checks"])
		]*/)
	]
)
