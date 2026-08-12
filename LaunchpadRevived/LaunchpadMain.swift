import AppKit

@main
enum LaunchpadMain {
    static func main() {
        if CommandLine.arguments.contains("--discover") {
            DiscoverCommand.run()
            return
        }

        _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
    }
}
