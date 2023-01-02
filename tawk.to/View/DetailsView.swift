//
//  DetailsView.swift
//  tawk.to
//
//  Created by Phua June Jin on 09/12/2022.
//

import SwiftUI
import Combine
import Foundation

struct DetailsView: View, KeyboardReadable {
    /// To dismiss a view in iOS 14 and below, we must use the PresentationMode property, "dismiss()" is only available in iOS 15+
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var viewModel: DetailsViewModel

    /// Arbitrary ID for scrollview to scroll when TextEditor is on focus, @FocusState is only available on iOS 15+
    private var scrollID = 1

    @State private var notes: String = ""
    @State private var isLoading: Bool = true
    @State private var showAlert: Bool = false
    @State private var showError: Bool = false
    @State private var savedSuccessful: Bool = true

    var imageView: some View {
        VStack {
            if isLoading {
                Rectangle()
                    .fill(Color(CustomColor.Skeleton.background))
                    .shimmer(isPresented: $isLoading)
            } else {
                Image(uiImage: viewModel.image)
                    .resizable()
            }
        }
        .frame(width: UIScreen.main.bounds.size.width - 16, height: UIScreen.main.bounds.size.width - 16)
    }

    var textPlaceholderView: some View {
        Rectangle()
            .fill(Color(CustomColor.Skeleton.background))
            .shimmer(isPresented: $isLoading)
            .frame(height: 10)
    }

    var followerView: some View {
        HStack {
            if isLoading {
                textPlaceholderView
                textPlaceholderView
            } else {
                Text("Followers: \(viewModel.followers)")
                    .frame(maxWidth: .infinity)
                    .font(.system(size: 12))
                Text("Following: \(viewModel.following)")
                    .frame(maxWidth: .infinity)
                    .font(.system(size: 12))
            }
        }
        .id(scrollID)
        .frame(width: UIScreen.main.bounds.size.width - 16)
    }

    var detailsView: some View {
        VStack {
            if isLoading {
                VStack {
                    /// There's in total of 8 displayable elements, so we need 8 placeholders
                    ForEach(0..<8) { _ in
                        textPlaceholderView
                    }
                }
            } else {
                Group {
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 14))
            }
        }
        .frame(width: UIScreen.main.bounds.size.width - 32)
        .padding(.all, 8)
        .border(Color.primary)
    }

    var notesView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Notes:")

            if isLoading {
                ZStack {
                    Rectangle()
                        .fill(Color(UIColor.systemBackground))
                        .border(Color.primary)

                    Rectangle()
                        .fill(Color(CustomColor.Skeleton.background))
                        .shimmer(isPresented: $isLoading)
                        .frame(width: UIScreen.main.bounds.size.width - 24, height: 48)
                }
            } else {
                TextEditor(text: $notes)
                    .border(Color.primary)
                    .font(.system(size: 14))
            }
        }
        .disabled(isLoading)
        .frame(width: UIScreen.main.bounds.size.width - 16, height: 90)
    }

    var saveButtonView: some View {
        Button {
            Task {
                savedSuccessful = await viewModel.saveNotes(notes: notes)

                if savedSuccessful { viewModel.notes = notes }

                showAlert = true
                UIApplication.shared.windows.first(where:\.isKeyWindow)?.endEditing(true)

                try? await Task.sleep(seconds: 2)

                showAlert = false
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
        .disabled(isLoading || showAlert)
    }

    var body: some View {
        ZStack {
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
                .disabled(isLoading)
                .onReceive(keyboardPublisher) { visible in
                    withAnimation { reader.scrollTo(scrollID, anchor: .top) }
                }
            }
        }
        .navigationBarTitle(isLoading ? "" : viewModel.navigationBarTitle)
        .alert(isPresented: $showError, content: {
            Alert(
                title: Text("Error"),
                message: Text("Failed to load the user's detail!"),
                dismissButton: .default(Text("Back"), action: {
                    presentationMode.wrappedValue.dismiss()
                })
            )
        })
        .toast(message: savedSuccessful ? "Saved successful" : "Saved failed" , isShowing: $showAlert, config: Toast.Config.init())
        .onLoad(perform: {
            isLoading = viewModel.detail == nil

            Task.detached { await viewModel.loadData() }
        })
        .onTapGesture { UIApplication.shared.windows.first(where:\.isKeyWindow)?.endEditing(true) }
        .onReceive(viewModel.didSetDetail) { _ in
            isLoading = false
            notes = viewModel.notes

            Task { await viewModel.updateSeen() }
        }
        .onReceive(MonitorConnection.shared.$hasConnection.dropFirst(), perform: { hasConnection in
            if hasConnection { Task { await viewModel.retryIfNecessary() } }
        })
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
