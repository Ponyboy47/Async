import Foundation
#if os(Linux)
import Dispatch
#endif

// MARK: - AsyncGroup – Struct

/**
The **AsyncGroup** struct facilitates working with groups of asynchronous blocks. Handles a internally `dispatch_group_t`.

Multiple dispatch blocks with GCD:

    let group = AsyncGroup()
    group.background {
        // Run on background queue
    }
    group.utility {
        // Run on untility queue, after the previous block
    }
    group.wait()

All moderns queue classes:

    group.main {}
    group.userInteractive {}
    group.userInitiated {}
    group.utility {}
    group.background {}

Custom queues:

    let customQueue = dispatch_queue_create("Label", DISPATCH_QUEUE_CONCURRENT)
    group.customQueue(customQueue) {}

Wait for group to finish:

    let group = AsyncGroup()
    group.background {
        // Do stuff
    }
    group.background {
        // Do other stuff in parallel
    }
    // Wait for both to finish
    group.wait()
    // Do rest of stuff

- SeeAlso: Grand Central Dispatch
*/
public struct AsyncGroup {

    // MARK: - Private properties and init

    /**
     Private property to internally on to a `dispatch_group_t`
    */
    private var group: DispatchGroup

    /**
     Private init that takes a `dispatch_group_t`
     */
    public init() {
        group = DispatchGroup()
    }

    /**
     Convenience for `dispatch_group_async()`

     - parameters:
         - block: The block that is to be passed to be run on the `queue`
         - queue: The queue on which the `block` is run.

     - SeeAlso: dispatch_group_async, dispatch_group_create
     */
    private func async(block: @escaping @convention(block) () -> Void, queue: GCD) {
        queue.queue.async(group: group, execute: block)
    }

    /**
     Convenience for `dispatch_group_enter()`. Used to add custom blocks to the current group.

     - SeeAlso: dispatch_group_enter, dispatch_group_leave
     */
    public func enter() {
        group.enter()
    }

    /**
     Convenience for `dispatch_group_leave()`. Used to flag a custom added block is complete.

     - SeeAlso: dispatch_group_enter, dispatch_group_leave
     */
    public func leave() {
        group.leave()
    }

    // MARK: - Instance methods

    /**
    Sends the a block to be run asynchronously on the main thread, in the current group.

    - parameters:
        - block: The block that is to be passed to be run on the main queue
    */
    public func main(_ block: @escaping @convention(block) () -> Void) {
        async(block: block, queue: .main)
    }

    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_USER_INTERACTIVE, in the current group.

     - parameters:
        - block: The block that is to be passed to be run on the queue
     */
    public func userInteractive(_ block: @escaping @convention(block) () -> Void) {
        async(block: block, queue: .userInteractive)
    }

    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_USER_INITIATED, in the current group.

     - parameters:
        - block: The block that is to be passed to be run on the queue
     */
    public func userInitiated(_ block: @escaping @convention(block) () -> Void) {
        async(block: block, queue: .userInitiated)
    }

    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of 
        QOS_CLASS_UTILITY, in the current block.

     - parameters:
        - block: The block that is to be passed to be run on the queue
     */
    public func utility(_ block: @escaping @convention(block) () -> Void) {
        async(block: block, queue: .utility)
    }

    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_BACKGROUND, in the current block.

     - parameters:
         - block: The block that is to be passed to be run on the queue
     */
    public func background(_ block: @escaping @convention(block) () -> Void) {
        async(block: block, queue: .background)
    }

    /**
     Sends the a block to be run asynchronously on a custom queue, in the current group.

     - parameters:
         - queue: Custom queue where the block will be run.
         - block: The block that is to be passed to be run on the queue
     */
    public func custom(queue: DispatchQueue, block: @escaping @convention(block) () -> Void) {
        async(block: block, queue: .custom(queue: queue))
    }

    /**
     Convenience function to call `dispatch_group_wait()` on the encapsulated block.
     Waits for the current group to finish, on any given thread.

     - parameters:
         - seconds: Max seconds to wait for block to finish. If value is nil, it uses DISPATCH_TIME_FOREVER. Default value is nil.

     - SeeAlso: dispatch_group_wait, DISPATCH_TIME_FOREVER
     */
    @discardableResult
    public func wait(seconds: Double? = nil) -> DispatchTimeoutResult {
        let timeout = seconds
            .flatMap { DispatchTime.now() + $0 }
            ?? .distantFuture
        return group.wait(timeout: timeout)
    }

    /**
     Convenience for `DispatchGroup().notify`. Waits for current group to finish before performing this block.

     - parameters:
         - queue: The queue on which the `block` is run
         - block: The block that is to be passed to be run on the `queue`

     - SeeAlso: dispatch_group_notify
    */
    public func notify(queue: DispatchQueue, block: @escaping @convention(block) () -> Void) {
        group.notify(queue: queue, execute: block)
    }

    /**
     Convenience for `DispatchGroup().notify`. Waits for current group to finish before performing this block. Block will be performed at the specified Quality of Service.

     - parameters:
         - qos: The quality of service level on which the `block` is run
         - block: The block that is to be passed to be run on the `queue`

     - SeeAlso: dispatch_group_notify
    */
    public func notify(qos: DispatchQoS.QoSClass, block: @escaping @convention(block) () -> Void) {
        group.notify(queue: .global(qos: qos), execute: block)
    }
}
