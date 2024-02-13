//
//  File.swift
//
//
//  Created by anderson on 2024/2/11.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct HomeFeature {
	struct State: Equatable {
		var isEnabledContentBlocker = false
	}

	enum Action: Equatable {
		case checkUserEnabledContentBlocker
		case scenePhaseBecomeActive
		case tapAboutButton 
		case tapDontTapMeButton
		case tapRefreshButton
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

		default: return .none
		}
	}
}

struct HomeView: View {
	let store: StoreOf<HomeFeature>
	@Environment(\.scenePhase) var scenePhase
	var body: some View {
		WithViewStore(store, observe: { $0 }) { _ in
			NavigationStack {
				VStack {
					setupDescription
					Spacer()
					dontTapMeButton
				}
				.navigationTitle("Blahker")
				.navigationBarTitleDisplayMode(.inline)
				.toolbar {
					ToolbarItem(placement: .topBarLeading) {
						refreshButton
					}
					ToolbarItem(placement: .topBarTrailing) {
						aboutButton
					}
				}
				.onChange(of: scenePhase, perform: { phase in
					switch phase {
					case .active:
						store.send(.scenePhaseBecomeActive)
					default: break
					}
				})
			}
			.preferredColorScheme(.dark)
		}
	}

	@MainActor
	@ViewBuilder
	private var setupDescription: some View {
		Text("""
		Blahker 致力于消除网站中的盖板广告，支持 Safari 浏览器。
		App 将会自动取得最新挡广告网站清单，你也可以透过左上角按钮手动更新。
		了解更多资讯，请参阅【关于】页面。
		""")
		.padding()
	}

	@MainActor
	@ViewBuilder
	private var dontTapMeButton: some View {
		Button {
			store.send(.tapDontTapMeButton)
		} label: {
			Text("别点我")
		}
		.foregroundStyle(.white)
		.font(.title)
	}

	@MainActor
	@ViewBuilder
	private var refreshButton: some View {
		Button {
			store.send(.tapRefreshButton)
		} label: {
			Image(systemName: "arrow.clockwise")
		}
		.buttonStyle(.plain)
	}

	@MainActor
	@ViewBuilder
	private var aboutButton: some View {
		Button {
			store.send(.tapAboutButton)
		} label: {
			Text("关于")
		}
		.buttonStyle(.plain)
	}
}

#Preview {
	HomeView(store: Store(initialState: HomeFeature.State(), reducer: { HomeFeature() }))
}
