//
//  AsyncBlockswift
//
//  Created by Tobias DM on 15/07/14.
//
//	OS X 10.10+ and iOS 8.0+
//	Only use with ARC
//
//	The MIT License (MIT)
//	Copyright (c) 2014 Tobias Due Munk
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy of
//	this software and associated documentation files (the "Software"), to deal in
//	the Software without restriction, including without limitation the rights to
//	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//	the Software, and to permit persons to whom the Software is furnished to do so,
//	subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//	FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//	COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//	IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Foundation
#if os(Linux)
import Dispatch
#endif

// MARK: - DSL for GCD queues

/**
 `GCD` is a convenience enum with cases to get `DispatchQueue` of different
 quality of service classes, as provided by `DispatchQueue.global` or
 `DispatchQueue` for main thread or a specific custom queue.

 let mainQueue = GCD.main
 let utilityQueue = GCD.utility
 let customQueue = GCD.custom(queue: aDispatchQueue)

 - SeeAlso: Grand Central Dispatch
 */
enum GCD {
    case main, userInteractive, userInitiated, utility, background, custom(queue: DispatchQueue)

    var queue: DispatchQueue {
        switch self {
        case .main: return .main
        case .userInteractive: return .global(qos: .userInteractive)
        case .userInitiated: return .global(qos: .userInitiated)
        case .utility: return .global(qos: .utility)
        case .background: return .global(qos: .background)
        case .custom(let queue): return queue
        }
    }
}

private class Reference<T> {
    var value: T?
}

public typealias Async = AsyncBlock<Void, Void>.Async
public typealias Sync = AsyncBlock<Void, Void>.Sync

// MARK: - Async – Struct

/**
The **Async** struct is the main part of the AsyncBlockframework. Handles an internally `@convention(block) () -> Swift.Void`.

Chainable dispatch blocks with GCD:

    AsyncBlockbackground {
    // Run on background queue
    }.main {
    // Run on main queue, after the previous block
    }

All moderns queue classes:

    AsyncBlockmain {}
    AsyncBlockuserInteractive {}
    AsyncBlockuserInitiated {}
    AsyncBlockutility {}
    AsyncBlockbackground {}

Custom queues:

    let customQueue = dispatch_queue_create("Label", DISPATCH_QUEUE_CONCURRENT)
    AsyncBlockcustomQueue(customQueue) {}

Dispatch block after delay:

    let seconds = 0.5
    AsyncBlockmain(after: seconds) {}

Cancel blocks not yet dispatched

    let block1 = AsyncBlockbackground {
        // Some work
    }
    let block2 = block1.background {
        // Some other work
    }
    AsyncBlockmain {
        // Cancel async to allow block1 to begin
        block1.cancel() // First block is NOT cancelled
        block2.cancel() // Second block IS cancelled
    }

Wait for block to finish:

    let block = AsyncBlockbackground {
        // Do stuff
    }
    // Do other stuff
    // Wait for "Do stuff" to finish
    block.wait()
    // Do rest of stuff

- SeeAlso: Grand Central Dispatch
*/
public struct AsyncBlock<In, Out> {

    // MARK: - Private properties and init

    /**
     Private property to hold internally on to a `@convention(block) () -> Swift.Void`
    */
    private let block: DispatchWorkItem

    private let input: Reference<In>?
    private let _output: Reference<Out>
    public var output: Out? {
        return _output.value
    }
    public struct Async {
        /**
        Sends the a block to be run asynchronously on the main thread.

        - parameters:
            - after: After how many seconds the block should be run.
            - block: The block that is to be passed to be run on the main queue

        - returns: An `Async` struct

        - SeeAlso: Has parity with non-static method
        */
        @discardableResult
        public static func main<O>(after seconds: Double? = nil, _ block: @escaping (Void) -> O) -> AsyncBlock<Void, O> {
            return AsyncBlock.async(after: seconds, block: block, queue: .main)
        }

        /**
         Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_USER_INTERACTIVE.

         - parameters:
            - after: After how many seconds the block should be run.
            - block: The block that is to be passed to be run on the queue

         - returns: An `Async` struct

         - SeeAlso: Has parity with non-static method
         */
        @discardableResult
        public static func userInteractive<O>(after seconds: Double? = nil, _ block: @escaping (Void) -> O) -> AsyncBlock<Void, O> {
            return AsyncBlock.async(after: seconds, block: block, queue: .userInteractive)
        }

        /**
         Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_USER_INITIATED.

         - parameters:
            - after: After how many seconds the block should be run.
            - block: The block that is to be passed to be run on the queue

         - returns: An `Async` struct

         - SeeAlso: Has parity with non-static method
         */
        @discardableResult
        public static func userInitiated<O>(after seconds: Double? = nil, _ block: @escaping (Void) -> O) -> AsyncBlock<Void, O> {
            return AsyncBlock.async(after: seconds, block: block, queue: .userInitiated)
        }

        /**
         Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_UTILITY.

         - parameters:
            - after: After how many seconds the block should be run.
            - block: The block that is to be passed to be run on queue

         - returns: An `Async` struct

         - SeeAlso: Has parity with non-static method
         */
        @discardableResult
        public static func utility<O>(after seconds: Double? = nil, _ block: @escaping (Void) -> O) -> AsyncBlock<Void, O> {
            return AsyncBlock.async(after: seconds, block: block, queue: .utility)
        }

        /**
         Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_BACKGROUND.

         - parameters:
            - after: After how many seconds the block should be run.
            - block: The block that is to be passed to be run on the queue

         - returns: An `Async` struct

         - SeeAlso: Has parity with non-static method
         */
        @discardableResult
        public static func background<O>(after seconds: Double? = nil, _ block: @escaping (Void) -> O) -> AsyncBlock<Void, O> {
            return AsyncBlock.async(after: seconds, block: block, queue: .background)
        }

        /**
         Sends the a block to be run asynchronously on a custom queue.

         - parameters:
            - after: After how many seconds the block should be run.
            - block: The block that is to be passed to be run on the queue

         - returns: An `Async` struct

         - SeeAlso: Has parity with non-static method
         */
        @discardableResult
        public static func custom<O>(queue: DispatchQueue, after seconds: Double? = nil, _ block: @escaping (Void) -> O) -> AsyncBlock<Void, O> {
            return AsyncBlock.async(after: seconds, block: block, queue: .custom(queue: queue))
        }
    }
    public struct Sync {
        /**
        Sends the a block to be run synchronously on the main thread.

        - parameters:
            - after: After how many seconds the block should be run.
            - block: The block that is to be passed to be run on the main queue

        - returns: An `Async` struct

        - SeeAlso: Has parity with non-static method
        */
        @discardableResult
        public static func main<O>(after seconds: UInt32? = nil, _ block: @escaping (Void) -> O) -> AsyncBlock<Void, O> {
            return AsyncBlock.sync(after: seconds, block: block, queue: .main)
        }

        /**
         Sends the a block to be run synchronously on a queue with a quality of service of QOS_CLASS_USER_INTERACTIVE.

         - parameters:
            - after: After how many seconds the block should be run.
            - block: The block that is to be passed to be run on the queue

         - returns: An `Async` struct

         - SeeAlso: Has parity with non-static method
         */
        @discardableResult
        public static func userInteractive<O>(after seconds: UInt32? = nil, _ block: @escaping (Void) -> O) -> AsyncBlock<Void, O> {
            return AsyncBlock.sync(after: seconds, block: block, queue: .userInteractive)
        }

        /**
         Sends the a block to be run synchronously on a queue with a quality of service of QOS_CLASS_USER_INITIATED.

         - parameters:
            - after: After how many seconds the block should be run.
            - block: The block that is to be passed to be run on the queue

         - returns: An `Async` struct

         - SeeAlso: Has parity with non-static method
         */
        @discardableResult
        public static func userInitiated<O>(after seconds: UInt32? = nil, _ block: @escaping (Void) -> O) -> AsyncBlock<Void, O> {
            return AsyncBlock.sync(after: seconds, block: block, queue: .userInitiated)
        }

        /**
         Sends the a block to be run synchronously on a queue with a quality of service of QOS_CLASS_UTILITY.

         - parameters:
            - after: After how many seconds the block should be run.
            - block: The block that is to be passed to be run on queue

         - returns: An `Async` struct

         - SeeAlso: Has parity with non-static method
         */
        @discardableResult
        public static func utility<O>(after seconds: UInt32? = nil, _ block: @escaping (Void) -> O) -> AsyncBlock<Void, O> {
            return AsyncBlock.sync(after: seconds, block: block, queue: .utility)
        }

        /**
         Sends the a block to be run synchronously on a queue with a quality of service of QOS_CLASS_BACKGROUND.

         - parameters:
            - after: After how many seconds the block should be run.
            - block: The block that is to be passed to be run on the queue

         - returns: An `Async` struct

         - SeeAlso: Has parity with non-static method
         */
        @discardableResult
        public static func background<O>(after seconds: UInt32? = nil, _ block: @escaping (Void) -> O) -> AsyncBlock<Void, O> {
            return AsyncBlock.sync(after: seconds, block: block, queue: .background)
        }

        /**
         Sends the a block to be run synchronously on a custom queue.

         - parameters:
            - after: After how many seconds the block should be run.
            - block: The block that is to be passed to be run on the queue

         - returns: An `Async` struct

         - SeeAlso: Has parity with non-static method
         */
        @discardableResult
        public static func custom<O>(queue: DispatchQueue, after seconds: UInt32? = nil, _ block: @escaping (Void) -> O) -> AsyncBlock<Void, O> {
            return AsyncBlock.sync(after: seconds, block: block, queue: .custom(queue: queue))
        }
    }


    /**
     Private init that takes a `@convention(block) () -> Swift.Void`
     */
    private init(_ block: DispatchWorkItem, input: Reference<In>? = nil, output: Reference<Out> = Reference(), async: Bool = true) {
        self.block = block
        self.input = input
        self._output = output
    }

    // MARK: - Static methods

    // MARK: - Private static methods

    /**
     Convenience for dispatch_async(). Encapsulates the block in a "true" GCD block using DISPATCH_BLOCK_INHERIT_QOS_CLASS.

     - parameters:
         - block: The block that is to be passed to be run on the `queue`
         - queue: The queue on which the `block` is run.

     - returns: An `Async` struct which encapsulates the `@convention(block) () -> Swift.Void`
     */

    private static func async<O>(after seconds: Double? = nil, block: @escaping (Void) -> O, queue: GCD) -> AsyncBlock<Void, O> {
        let reference = Reference<O>()
        let block = DispatchWorkItem(block: {
            reference.value = block()
        })

        if let seconds = seconds {
            let time = DispatchTime.now() + seconds
            queue.queue.asyncAfter(deadline: time, execute: block)
        } else {
            queue.queue.async(execute: block)
        }

        // Wrap block in a struct since @convention(block) () -> Swift.Void can't be extended
        return AsyncBlock<Void, O>(block, output: reference)
    }

    /**
     Convenience for dispatch_sync(). Encapsulates the block in a "true" GCD block using DISPATCH_BLOCK_INHERIT_QOS_CLASS.

     - parameters:
         - block: The block that is to be passed to be run on the `queue`
         - queue: The queue on which the `block` is run.

     - returns: An `Async` struct which encapsulates the `@convention(block) () -> Swift.Void`
     */

    private static func sync<O>(after seconds: UInt32? = nil, block: @escaping (Void) -> O, queue: GCD) -> AsyncBlock<Void, O> {
        let reference = Reference<O>()
        let block = DispatchWorkItem(block: {
            reference.value = block()
        })

        if let seconds = seconds {
            let wait = DispatchWorkItem(block: {
                sleep(seconds)
            })
            queue.queue.sync(execute: wait)
        }
        queue.queue.sync(execute: block)

        // Wrap block in a struct since @convention(block) () -> Swift.Void can't be extended
        return AsyncBlock<Void, O>(block, output: reference, async: false)
    }

    // MARK: - Instance methods (matches static ones)

    /**
    Sends the a block to be run asynchronously on the main thread, after the current block has finished.

    - parameters:
        - after: After how many seconds the block should be run.
        - block: The block that is to be passed to be run on the main queue

    - returns: An `Async` struct

    - SeeAlso: Has parity with static method
    */
    @discardableResult
    public func main<O>(after seconds: Double? = nil, _ chainingBlock: @escaping (Out) -> O) -> AsyncBlock<Out, O> {
        return chain(after: seconds, block: chainingBlock, queue: .main)
    }

    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_USER_INTERACTIVE, after the current block has finished.

     - parameters:
         - after: After how many seconds the block should be run.
         - block: The block that is to be passed to be run on the queue

     - returns: An `Async` struct

     - SeeAlso: Has parity with static method
     */
    @discardableResult
    public func userInteractive<O>(after seconds: Double? = nil, _ chainingBlock: @escaping (Out) -> O) -> AsyncBlock<Out, O> {
        return chain(after: seconds, block: chainingBlock, queue: .userInteractive)
    }

    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_USER_INITIATED, after the current block has finished.

     - parameters:
         - after: After how many seconds the block should be run.
         - block: The block that is to be passed to be run on the queue

     - returns: An `Async` struct

     - SeeAlso: Has parity with static method
     */
    @discardableResult
    public func userInitiated<O>(after seconds: Double? = nil, _ chainingBlock: @escaping (Out) -> O) -> AsyncBlock<Out, O> {
        return chain(after: seconds, block: chainingBlock, queue: .userInitiated)
    }

    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_UTILITY, after the current block has finished.

     - parameters:
         - after: After how many seconds the block should be run.
         - block: The block that is to be passed to be run on the queue

     - returns: An `Async` struct

     - SeeAlso: Has parity with static method
     */
    @discardableResult
    public func utility<O>(after seconds: Double? = nil, _ chainingBlock: @escaping (Out) -> O) -> AsyncBlock<Out, O> {
        return chain(after: seconds, block: chainingBlock, queue: .utility)
    }

    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_BACKGROUND, after the current block has finished.

     - parameters:
         - after: After how many seconds the block should be run.
         - block: The block that is to be passed to be run on the queue

     - returns: An `Async` struct

     - SeeAlso: Has parity with static method
     */
    @discardableResult
    public func background<O>(after seconds: Double? = nil, _ chainingBlock: @escaping (Out) -> O) -> AsyncBlock<Out, O> {
        return chain(after: seconds, block: chainingBlock, queue: .background)
    }

    /**
     Sends the a block to be run asynchronously on a custom queue, after the current block has finished.

     - parameters:
         - after: After how many seconds the block should be run.
         - block: The block that is to be passed to be run on the queue

     - returns: An `Async` struct

     - SeeAlso: Has parity with static method
     */
    @discardableResult
    public func custom<O>(queue: DispatchQueue, after seconds: Double? = nil, _ chainingBlock: @escaping (Out) -> O) -> AsyncBlock<Out, O> {
        return chain(after: seconds, block: chainingBlock, queue: .custom(queue: queue))
    }

    // MARK: - Instance methods

    /**
    Convenience function to call `dispatch_block_cancel()` on the encapsulated block.
    Cancels the current block, if it hasn't already begun running to GCD.

    Usage:

        let block1 = AsyncBlockbackground {
            // Some work
        }
        let block2 = block1.background {
            // Some other work
        }
        AsyncBlockmain {
            // Cancel async to allow block1 to begin
            block1.cancel() // First block is NOT cancelled
            block2.cancel() // Second block IS cancelled
        }

    */
    public func cancel() {
        block.cancel()
    }

    /**
     Convenience function to call `dispatch_block_wait()` on the encapsulated block.
     Waits for the current block to finish, on any given thread.

     - parameters:
        - seconds: Max seconds to wait for block to finish. If value is 0.0, it uses DISPATCH_TIME_FOREVER. Default value is 0.

     - SeeAlso: dispatch_block_wait, DISPATCH_TIME_FOREVER
     */
    @discardableResult
    public func wait(seconds: Double? = nil) -> DispatchTimeoutResult {
        let timeout = seconds
            .flatMap { DispatchTime.now() + $0 }
            ?? .distantFuture
        return block.wait(timeout: timeout)
    }

    // MARK: Private instance methods

    /**
     Convenience for `dispatch_block_notify()` to

     - parameters:
         - block: The block that is to be passed to be run on the `queue`
         - queue: The queue on which the `block` is run.

     - returns: An `Async` struct which encapsulates the `@convention(block) () -> Swift.Void`, which is called when the current block has finished.

     - SeeAlso: dispatch_block_notify, dispatch_block_create
     */

    private func chain<O>(after seconds: Double? = nil, block chainingBlock: @escaping (Out) -> O, queue: GCD) -> AsyncBlock<Out, O> {
        let reference = Reference<O>()
        let dispatchWorkItem = DispatchWorkItem(block: {
            reference.value = chainingBlock(self._output.value!)
        })

        let queue = queue.queue
        if let seconds = seconds {
            block.notify(queue: queue) {
                let time = DispatchTime.now() + seconds
                queue.asyncAfter(deadline: time, execute: dispatchWorkItem)
            }
        } else {
            block.notify(queue: queue, execute: dispatchWorkItem)
        }

        // See AsyncBlock.async() for comments
        return AsyncBlock<Out, O>(dispatchWorkItem, input: self._output, output: reference)
    }
}
