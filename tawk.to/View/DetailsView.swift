//
//  DetailsView.swift
//  tawk.to
//
//  Created by Phua June Jin on 09/12/2022.
//

import SwiftUI
import Combine
import Foundation

enum LoadingState {
    case loading
    case success
}

struct DetailsView: View, KeyboardReadable {
    @EnvironmentObject var viewModel: DetailsViewModel

    /// Arbitrary ID to scroll to when TextEditor is on focus, @FocusState is only available on iOS 15+
    private var scrollID = 1

    @State private var notes: String = ""
    @State private var isLoading: Bool = true
    @State private var showToast: Bool = false
    @State private var savedSuccessful: Bool = true
    @State private var state: LoadingState = .loading

    var imageView: some View {
        VStack {
            Image(uiImage: viewModel.image)
                .resizable()
        }
        .shimmer(isPresented: $isLoading)
        .frame(width: UIScreen.main.bounds.size.width - 16, height: UIScreen.main.bounds.size.width - 16)
    }

    var followerView: some View {
        HStack {
            Text("Followers: \(viewModel.followers)")
                .frame(maxWidth: .infinity)
                .font(.system(size: 12))
            Text("Following: \(viewModel.following)")
                .frame(maxWidth: .infinity)
                .font(.system(size: 12))
        }
        .id(scrollID)
        .shimmer(isPresented: $isLoading)
        .frame(width: UIScreen.main.bounds.size.width - 16)
    }

    var detailsView: some View {
        VStack {
            Group {
                if isLoading {
                    /// Empty text as placeholder, the reason we are using 9 is because there's 9 possible field to display
                    ForEach(0..<9) { _ in
                        Text("")
                    }
                } else {
                    if !viewModel.name.isEmpty {
                        Text("Name: \(viewModel.name)")
                    }
                    if !viewModel.login.isEmpty {
                        Text("Username: \(viewModel.login)")
                    }
                    if !viewModel.bio.isEmpty {
                        Text("Bio: \(viewModel.bio)")
                    }
                    if !viewModel.blog.isEmpty {
                        Text("Blog: \(viewModel.blog)")
                    }
                    if !viewModel.email.isEmpty {
                        Text("Email: \(viewModel.email)")
                    }
                    if !viewModel.twitter.isEmpty {
                        Text("Twitter: \(viewModel.twitter)")
                    }
                    if !viewModel.location.isEmpty {
                        Text("Location: \(viewModel.location)")
                    }
                    if !viewModel.company.isEmpty {
                        Text("Company: \(viewModel.company)")
                    }
                    if !viewModel.public_repos.isEmpty {
                        Text("Repositories: \(viewModel.public_repos)")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.system(size: 14))
        }
        .shimmer(isPresented: $isLoading)
        .frame(width: UIScreen.main.bounds.size.width - 32)
        .padding(.all, 8)
        .border(Color.primary)
    }

    var notesView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Notes:")

            TextEditor(text: $notes)
                .shimmer(isPresented: $isLoading)
                .border(Color.primary)
                .font(.system(size: 14))
        }
        .frame(width: UIScreen.main.bounds.size.width - 16, height: 90)
    }

    var saveButtonView: some View {
        Button {
            Task {
                savedSuccessful = await viewModel.saveNotes(notes: notes)

                if savedSuccessful { viewModel.notes = notes }

                showToast = true
                UIApplication.shared.windows.first(where:\.isKeyWindow)?.endEditing(true)

                try? await Task.sleep(seconds: 2)

                showToast = false
            }
        } label: {
            Text("Save")
                .foregroundColor(Color.primary)
                .padding(.vertical, 8)
                .padding(.horizontal, 32)
                .overlay(
                    Rectangle()
                        .foregroundColor(Color.secondary)
                        .shadow(color: .secondary, radius: 5, x: 3, y: 3)
                )
        }
        .disabled(showToast)
    }

    var mainView: some View {
        ScrollViewReader { reader in
            ScrollView(showsIndicators: false) {
                VStack {
                    Spacer(minLength: 8)

                    imageView
                    followerView
                    detailsView
                    notesView
                    saveButtonView

                    Spacer(minLength: 8)
                }
            }
            .onReceive(keyboardPublisher) { visible in
                withAnimation { reader.scrollTo(scrollID, anchor: .top) }
            }
        }
    }

    var body: some View {
        mainView
            .onLoad { Task { await viewModel.loadData() } }
            .navigationBarTitle(viewModel.navigationBarTitle)
            .onTapGesture { UIApplication.shared.windows.first(where:\.isKeyWindow)?.endEditing(true) }
            .toast(message: savedSuccessful ? "Saved successful" : "Saved failed" , isShowing: $showToast, config: Toast.Config.init())
            .onReceive(MonitorConnection.shared.$hasConnection.dropFirst(), perform: { hasConnection in
                if hasConnection { Task { await viewModel.retryIfNecessary() } }
            })
            .onReceive(viewModel.didSetDetail) { _ in
                state = .success
                isLoading = false
                notes = viewModel.notes

                Task { await viewModel.updateSeen() }
            }
    }
}

struct DetailsView_Previews: PreviewProvider {
    static var previews: some View {
        /// Preview using actual data (id = 1, login = "mojombo")
        let user = User()
        user.id = 1
        user.login = "mojombo"
        user.notes = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."

        return DetailsView().environmentObject(DetailsViewModel(user: user))
    }
}
