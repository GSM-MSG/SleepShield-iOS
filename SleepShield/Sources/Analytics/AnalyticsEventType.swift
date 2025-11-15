import Foundation

public protocol AnalyticsEventType: Sendable {
  var name: String { get }
  var properties: [String: Any]? { get }
}
