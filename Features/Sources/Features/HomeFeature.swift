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
		@PresentationState var alert: AlertState<Action.Alert>?
		var isEnabledContentBlocker = false
	}

	enum Action: Equatable {
		case alert(PresentationAction<Alert>)
		case checkUserEnabledContentBlocker
		case scenePhaseBecomeActive
		case tapAboutButton 
		case tapDontTapMeButton
		case tapRefreshButton
		case userEnableContentBlocker(Bool)
		
		enum Alert {
			case smallDonation
			case mediumDonation
			case largeDonation
			case rate5Star
		}
	}

	@Dependency(\.contentBlockerService) var contentBlockerService
	@Dependency(\.openURL) var openURL
	
	func reduce(into state: inout State, action: Action) -> Effect<Action> {
		switch action {
		case let .alert(.presented(alert)):
			switch alert {
			case .smallDonation:
				return .none
			case .mediumDonation:
				return .none
			case .largeDonation:
				return .none
			case .rate5Star:
				return .run { send in
					let url = URL(string: "https://apps.apple.com/hk/app/blahker-巴拉剋/id1182699267")!
					await openURL(url)
				}
			}
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

		case .tapDontTapMeButton:
			state.alert = AlertState(title: TextState("支持开发者"), message: TextState("Blahker 的维护包含不断更新挡广告清淡。如果有你的支持一定会更好"), buttons: [
				ButtonState(action: .smallDonation, label: {
					TextState("打赏小小费")
				}),
				ButtonState(action: .mediumDonation, label: {
					TextState("打赏小费")
				}),
				ButtonState(action: .largeDonation, label: {
					TextState("破费")
				}),
				ButtonState(action: .rate5Star, label: {
					TextState("我不给钱，给个五星评分总行了吧")
				}),
				ButtonState(role: .cancel, label: {
					TextState("算了吧，不值得")
				})
			])
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
		.alert(store: store.scope(state: \.$alert, action: \.alert))
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
