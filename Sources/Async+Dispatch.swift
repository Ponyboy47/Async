import Foundation
#if !os(Linux)

// MARK: - Extension for `qos_class_t`

/**
Extension to add description string for each quality of service class.
*/
public extension qos_class_t {

    /**
     Description of the `qos_class_t`. E.g. "Main", "User Interactive", etc. for the given Quality of Service class.
     */
    var description: String {
        switch self {
        case qos_class_main(): return "Main"
        case DispatchQoS.QoSClass.userInteractive.rawValue: return "User Interactive"
        case DispatchQoS.QoSClass.userInitiated.rawValue: return "User Initiated"
        case DispatchQoS.QoSClass.default.rawValue: return "Default"
        case DispatchQoS.QoSClass.utility.rawValue: return "Utility"
        case DispatchQoS.QoSClass.background.rawValue: return "Background"
        case DispatchQoS.QoSClass.unspecified.rawValue: return "Unspecified"
        default: return "Unknown"
        }
    }
}

// MARK: - Extension for `DispatchQueue.GlobalAttributes`

/**
 Extension to add description string for each quality of service class.
 */
public extension DispatchQoS.QoSClass {

    var description: String {
        switch self {
        case DispatchQoS.QoSClass(rawValue: qos_class_main())!: return "Main"
        case .userInteractive: return "User Interactive"
        case .userInitiated: return "User Initiated"
        case .default: return "Default"
        case .utility: return "Utility"
        case .background: return "Background"
        case .unspecified: return "Unspecified"
        }
    }
}
#endif
