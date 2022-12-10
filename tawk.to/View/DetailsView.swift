//
//  DetailsView.swift
//  tawk.to
//
//  Created by Phua June Jin on 09/12/2022.
//

import SwiftUI
import Combine
import Foundation

struct DetailsView: View {
    @EnvironmentObject var model: User

    @State private var notes: String = ""
    @State private var hidden: Bool = true
    @State private var showAlert: Bool = false
    @State private var savedSuccessful: Bool = true

    var body: some View {
        ZStack {
            if hidden {
                ProgressView()
            }

            VStack {
                Image(uiImage: UIImage(data: model.detail?.image ?? Data()) ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)

                HStack {
                    Text("Followers: " + String(model.detail?.followers ?? 0))
                        .frame(maxWidth: .infinity)
                        .font(.system(size: 12))
                    Text("Following: " + String(model.detail?.following ?? 0))
                        .frame(maxWidth: .infinity)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 16)

                Spacer()

                VStack(alignment: .leading) {
                    if let detail = model.detail {
                        if let detail = detail.name, !detail.isEmpty {
                            Text("name: " + detail)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.system(size: 14))
                        }

                        if let bio = detail.bio, !bio.isEmpty {
                            Text("bio: " + bio)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.system(size: 14))
                        }

                        if let blog = detail.blog, !blog.isEmpty {
                            Text("blog: " + blog)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.system(size: 14))
                        }

                        if let email = detail.email, !email.isEmpty {
                            Text("email: " + email)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.system(size: 14))
                        }

                        if let twitter = detail.twitter_username, !twitter.isEmpty {
                            Text("twitter: " + twitter)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.system(size: 14))
                        }

                        if let location = detail.location, !location.isEmpty {
                            Text("location: " + location)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.system(size: 14))
                        }

                        if let company = detail.company, !company.isEmpty {
                            Text("company: " + company)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.system(size: 14))
                        }
                    }
                }
                .frame(width: UIScreen.main.bounds.size.width - 32)
                .padding(.all, 8)
                .border(Color.primary)

                Spacer(minLength: 16)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes:")
                    TextEditor(text: $notes)
                        .border(Color.primary)
                        .font(.system(size: 14))
                }
                .frame(width: UIScreen.main.bounds.size.width - 16, height: UIScreen.main.bounds.size.height * 0.15)

                Spacer(minLength: 24)

                Button {
                    model.saveNotes(notes: notes) { success in
                        savedSuccessful = success

                        if success {
                            model.detail?.notes = notes
                        }

                        showAlert = true

                        DispatchQueue.main.async { UIApplication.shared.windows.first(where:\.isKeyWindow)?.endEditing(true) }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: { showAlert = false })
                    }
                } label: {
                    Text("Save")
                        .foregroundColor(Color.primary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 32)
                        .overlay(
                            Rectangle()
                                .foregroundColor(Color.secondary)
                                .shadow(color: .secondary, radius: 5, x: 5, y: 5)
                        )
                }
                .disabled(showAlert)

                Spacer(minLength: 24)
            }
            .opacity(hidden ? 0 : 1)
            .navigationBarTitle(hidden ? "" : model.detail?.name ?? "")
            .onReceive(model.didSetDetail) { _ in hidden = false }
            .toast(message: savedSuccessful ? "Saved successful" : "Saved failed" , isShowing: $showAlert, config: Toast.Config.init())
            .onLoad(perform: {
                if model.detail == nil {
                    model.fetchDetails()
                } else {
                    hidden = false
                }

                notes = model.detail?.notes ?? ""
            })
        }
        .onTapGesture {
            UIApplication.shared.windows.first(where:\.isKeyWindow)?.endEditing(true)
        }
    }
}
