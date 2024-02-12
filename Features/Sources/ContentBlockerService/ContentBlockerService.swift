//
//  File.swift
//
//
//  Created by Anderson  on 2024/2/11.
//

import Dependencies
import Foundation
import SafariServices

public struct ContentBlockerService {
	public var checkUserEnabledContentBlocker: (String) async -> Bool
}

extension ContentBlockerService: DependencyKey {
	public static var liveValue = ContentBlockerService { identifier in
		await withCheckedContinuation { continuation in
			SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: identifier) { state, error in
				if let state {
					continuation.resume(returning: state.isEnabled)
				} else {
					continuation.resume(returning: false)
				}
				if let error {
					// log
				}
			}
		}
	}
}

extension ContentBlockerService: TestDependencyKey {
	public static var testValue = ContentBlockerService(checkUserEnabledContentBlocker: unimplemented("checkUserEnabledContentBlocker"))
}

public extension DependencyValues {
	var contentBlockerService: ContentBlockerService {
		get { self[ContentBlockerService.self] }
		set { self[ContentBlockerService.self] = newValue }
	}
}
