import Foundation

public protocol AnalyticsUserPropertyType: Sendable {
  var name: String { get }
  var value: Any { get }
}
