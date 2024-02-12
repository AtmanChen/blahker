import ComposableArchitecture
import SwiftUI
import ContentBlockerService

@main
struct BlahkerApp: App {
	var body: some Scene {
		WindowGroup {
			AppView(
				store: .init(
					initialState: AppFeature.State(),
					reducer: { AppFeature() }
				)
			)
		}
	}
}

struct AppFeature: Reducer {
	struct State: Equatable {
		var isEnabledContentBlocker = false
	}
	enum Action: Equatable {
		case scenePhaseBecomeActive
		case checkUserEnabledContentBlocker
		case userEnableContentBlocker(Bool)
	}
	
	@Dependency(\.contentBlockerService) var contentBlockerService
	
	
	func reduce(into state: inout State, action: Action) -> Effect<Action> {
		switch action {
		case .scenePhaseBecomeActive:
			return .send(.checkUserEnabledContentBlocker)
			
		case .checkUserEnabledContentBlocker:
			return .run { send in
				let extensionId = "com.elaborapp.Blahker.ContentBlocker"
				let isEnabled = await contentBlockerService.checkUserEnabledContentBlocker(extensionId)
				await send(.userEnableContentBlocker(isEnabled))
			}
			
		case .userEnableContentBlocker(let isEnabled):
			state.isEnabledContentBlocker = isEnabled
			return .none
		}
	}
}


struct AppView: View {
	let store: StoreOf<AppFeature>
	@Environment(\.scenePhase) var scenePhase
	var body: some View {
		WithViewStore(store, observe: { $0.isEnabledContentBlocker }) { viewStore in
			let isEnabledContentBlocker = viewStore.state
			Text("Content Blocker is \(isEnabledContentBlocker ? "Enabled" : "Disabled")")
				.onChange(of: scenePhase) { phase in
					switch phase {
					case .active:
						store.send(.scenePhaseBecomeActive)
					case .background, .inactive:
						break
					@unknown default:
						break
					}
				}
		}
	}
}
