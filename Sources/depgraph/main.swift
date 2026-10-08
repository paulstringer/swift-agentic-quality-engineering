import DepGraphCore
import Foundation

let result = CLI.run(arguments: Array(CommandLine.arguments.dropFirst()))
FileHandle.standardOutput.write(Data(result.output.utf8))
FileHandle.standardError.write(Data(result.errorOutput.utf8))
exit(result.exitCode)
