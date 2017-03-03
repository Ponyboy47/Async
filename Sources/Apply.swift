import Foundation
#if os(Linux)
import Dispatch
#endif

// MARK: - Apply - DSL for `dispatch_apply`

/**
`Apply` is an empty struct with convenience static functions to parallelize a for-loop, as provided by `dispatch_apply`.

    Apply.background(100) { i in
        // Calls blocks in parallel
    }

`Apply` runs a block multiple times, before returning. If you want run the block asynchronously from the current thread, wrap it in an `Async` block:

    Async.background {
        Apply.background(100) { i in
            // Calls blocks in parallel asynchronously
        }
    }

- SeeAlso: Grand Central Dispatch, dispatch_apply
*/
public struct Apply {

    /**
     Block is run any given amount of times on a queue with a quality of service of QOS_CLASS_USER_INTERACTIVE. The block is being passed an index parameter.

     - parameters:
         - iterations: How many times the block should be run. Index provided to block goes from `0..<iterations`
         - block: The block that is to be passed to be run on a .
     */
    public static func userInteractive(_ iterations: Int, block: @escaping (Int) -> Void) {
        GCD.userInteractive.queue.async {
            DispatchQueue.concurrentPerform(iterations: iterations, execute: block)
        }
    }

    /**
     Block is run any given amount of times on a queue with a quality of service of QOS_CLASS_USER_INITIATED. The block is being passed an index parameter.

     - parameters:
         - iterations: How many times the block should be run. Index provided to block goes from `0..<iterations`
         - block: The block that is to be passed to be run on a .
     */
    public static func userInitiated(_ iterations: Int, block: @escaping (Int) -> Void) {
        GCD.userInitiated.queue.async {
            DispatchQueue.concurrentPerform(iterations: iterations, execute: block)
        }
    }

    /**
     Block is run any given amount of times on a queue with a quality of service of QOS_CLASS_UTILITY. The block is being passed an index parameter.

     - parameters:
         - iterations: How many times the block should be run. Index provided to block goes from `0..<iterations`
         - block: The block that is to be passed to be run on a .
     */
    public static func utility(_ iterations: Int, block: @escaping (Int) -> Void) {
        GCD.utility.queue.async {
            DispatchQueue.concurrentPerform(iterations: iterations, execute: block)
        }
    }

    /**
     Block is run any given amount of times on a queue with a quality of service of QOS_CLASS_BACKGROUND. The block is being passed an index parameter.

     - parameters:
         - iterations: How many times the block should be run. Index provided to block goes from `0..<iterations`
         - block: The block that is to be passed to be run on a .
     */
    public static func background(_ iterations: Int, block: @escaping (Int) -> Void) {
        GCD.background.queue.async {
            DispatchQueue.concurrentPerform(iterations: iterations, execute: block)
        }
    }

    /**
     Block is run any given amount of times on a custom queue. The block is being passed an index parameter.

     - parameters:
         - iterations: How many times the block should be run. Index provided to block goes from `0..<iterations`
         - block: The block that is to be passed to be run on a .
     */
    public static func custom(queue: DispatchQueue, iterations: Int, block: @escaping (Int) -> Void) {
        queue.async {
            DispatchQueue.concurrentPerform(iterations: iterations, execute: block)
        }
    }
}
