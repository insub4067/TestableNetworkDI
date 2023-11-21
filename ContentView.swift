//
//  ContentView.swift
//  SwiftUIPractice
//
//  Created by 김인섭 on 10/31/23.
//

import Combine
import SwiftUI
import MightyCombine

struct ContentView: View {
    
    @StateObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack {
            if let error = viewModel.error {
                Text(error)
            }
            if let user = viewModel.user {
                Text(String(user.id))
            }
            Button("Button", action: {
                viewModel.getUser()
            })
        }
    }
}

@MainActor class ContentViewModel: ObservableObject {
    
    var cancellable = Set<AnyCancellable>()
    @Published var user: User? = nil
    @Published var error: String? = nil
    
    let api: GitHubAPIable
    
    init(api: GitHubAPIable) {
        self.api = api
    }
    
    func getUser() {
        Task {
            do {
                self.user = try await api.getUser("octocat").asyncThrows
            } catch {
                self.error = "Somethign went wrong"
            }
        }
    }
}

protocol GitHubAPIable {
    var getUser: (String) -> AnyPublisher<User, Error> { get set }
}

extension GitHubAPIable where Self == GitHubAPI {
    static var live: GitHubAPIable { GitHubAPI() }
    static var fake: GitHubAPIable {
        GitHubAPI(session: URLSession.mockSession)
    }
}

class GitHubAPI: GitHubAPIable {
    
    let session: URLSessionable
    
    init(session: URLSessionable = URLSession.shared) {
        self.session = session
    }
    
    lazy var getUser: (String) -> AnyPublisher<User, Error> = { username in
        EndPoint
            .init("https://api.github.com")
            .urlPaths(["/users", "/\(username)"])
            .requestPublisher(
                expect: User.self,
                with: self.session
            )
    }
}

struct User: Codable {
    let id: Int
}

#Preview {
    let viewModel = ContentViewModel(api: .fake)
    return ContentView(viewModel: viewModel)
}
