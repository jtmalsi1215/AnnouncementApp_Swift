import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var store: AnnouncementStore

    var body: some View {
        Group {
            if auth.isCheckingAuth {
                ZStack {
                    Color.white.ignoresSafeArea()
                    ProgressView()
                }
            } else if auth.firebaseUser != nil {
                NavigationStack {
                    DashboardView()
                        .navigationBarBackButtonHidden(true)
                }
            } else {
                AuthView()
            }
        }
        .onAppear {
            store.listenToReadAnnouncements(for: auth.firebaseUser?.uid)
        }
        .onChange(of: auth.firebaseUser?.uid) { userId in
            store.listenToReadAnnouncements(for: userId)
        }
    }
}

struct AuthView: View {
    @EnvironmentObject private var auth: AuthService

    @State private var isLoginView = true
    @State private var showPanel = true
    @State private var liftLogo = false
    @State private var isSwitching = false

    @State private var loginEmail = ""
    @State private var loginPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""
    @State private var signUpEmail = ""
    @State private var signUpPassword = ""

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                (isLoginView ? AppTheme.accentYellow : Color.white)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.36), value: isLoginView)

                VStack(alignment: .leading) {
                    AcadvisoryLogoView()
                        .padding(.leading, 36)
                        .padding(.trailing, 24)
                        .padding(.top, liftLogo ? 34 : 58)
                        .animation(.easeInOut(duration: 0.32), value: liftLogo)
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack {
                    if isLoginView {
                        LoginPanel(
                            email: $loginEmail,
                            password: $loginPassword,
                            onSignIn: {
                                auth.signIn(email: loginEmail, password: loginPassword)
                            },
                            onOpenSignUp: {
                                switchAuthView(openLogin: false)
                            }
                        )
                        .transition(.opacity)
                    } else {
                        SignUpPanel(
                            firstName: $firstName,
                            lastName: $lastName,
                            username: $username,
                            email: $signUpEmail,
                            password: $signUpPassword,
                            onSignUp: {
                                auth.signUp(
                                    firstName: firstName,
                                    lastName: lastName,
                                    username: username,
                                    email: signUpEmail,
                                    password: signUpPassword
                                )
                            },
                            onOpenLogin: {
                                switchAuthView(openLogin: true)
                            }
                        )
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 34)
                .padding(.bottom, 22 + geometry.safeAreaInsets.bottom)
                .frame(maxWidth: .infinity)
                .frame(height: geometry.size.height * 0.80)
                .background(isLoginView ? Color.white : AppTheme.accentYellow)
                .clipShape(.rect(topLeadingRadius: 82, topTrailingRadius: 82))
                .padding(.bottom, -geometry.safeAreaInsets.bottom)
                .offset(y: showPanel ? 0 : geometry.size.height * 0.8)
            }
        }
    }

    private func switchAuthView(openLogin: Bool) {
        guard isLoginView != openLogin, !isSwitching, !auth.isAuthLoading else { return }
        isSwitching = true
        auth.authMessage = nil

        withAnimation(.easeInOut(duration: 0.32)) {
            showPanel = false
            liftLogo = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            isLoginView = openLogin

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
                withAnimation(.easeInOut(duration: 0.32)) {
                    showPanel = true
                    liftLogo = false
                }
                isSwitching = false
            }
        }
    }
}

struct LoginPanel: View {
    @EnvironmentObject private var auth: AuthService
    @Binding var email: String
    @Binding var password: String
    let onSignIn: () -> Void
    let onOpenSignUp: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer().frame(height: 22)

                Text("LOGIN")
                    .font(.system(size: 34, weight: .black))
                    .tracking(-0.5)

                Spacer().frame(height: 42)

                AuthInputField(
                    placeholder: "EMAIL",
                    text: $email,
                    fillColor: AppTheme.formGray,
                    keyboardType: .emailAddress,
                    isEnabled: !auth.isAuthLoading
                )

                Spacer().frame(height: 18)

                AuthInputField(
                    placeholder: "PASSWORD",
                    text: $password,
                    fillColor: AppTheme.formGray,
                    isSecure: true,
                    isEnabled: !auth.isAuthLoading
                )

                HStack {
                    Spacer()
                    Button("Forgot Password?") { }
                        .font(.system(size: 13))
                        .foregroundStyle(.black)
                        .disabled(auth.isAuthLoading)
                        .padding(.top, 10)
                }

                if let message = auth.authMessage {
                    Spacer().frame(height: 8)
                    AuthMessageView(text: message)
                }

                Spacer().frame(height: 26)

                RoundedActionButton(
                    title: auth.isAuthLoading ? "Signing In..." : "Sign In",
                    background: AppTheme.accentYellow,
                    foreground: .black,
                    disabled: auth.isAuthLoading,
                    action: onSignIn
                )

                Spacer().frame(height: 28)

                Button(action: onOpenSignUp) {
                    HStack(spacing: 0) {
                        Text("Don't have an account yet? ")
                            .font(.system(size: 13))
                            .foregroundStyle(.black.opacity(0.86))
                        Text("SIGN UP")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(.black)
                    }
                }
                .buttonStyle(.plain)
                .disabled(auth.isAuthLoading)
            }
        }
    }
}

struct SignUpPanel: View {
    @EnvironmentObject private var auth: AuthService
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var username: String
    @Binding var email: String
    @Binding var password: String
    let onSignUp: () -> Void
    let onOpenLogin: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Text("SIGN UP")
                    .font(.system(size: 34, weight: .black))
                    .tracking(-0.5)

                Spacer().frame(height: 12)

                AuthInputField(placeholder: "FIRST NAME", text: $firstName, fillColor: .white, hasShadow: true, isEnabled: !auth.isAuthLoading)
                Spacer().frame(height: 10)
                AuthInputField(placeholder: "LAST NAME", text: $lastName, fillColor: .white, hasShadow: true, isEnabled: !auth.isAuthLoading)
                Spacer().frame(height: 10)
                AuthInputField(placeholder: "USERNAME", text: $username, fillColor: .white, hasShadow: true, isEnabled: !auth.isAuthLoading)
                Spacer().frame(height: 10)
                AuthInputField(placeholder: "EMAIL", text: $email, fillColor: .white, hasShadow: true, keyboardType: .emailAddress, isEnabled: !auth.isAuthLoading)
                Spacer().frame(height: 10)
                AuthInputField(placeholder: "PASSWORD", text: $password, fillColor: .white, isSecure: true, hasShadow: true, isEnabled: !auth.isAuthLoading)

                if let message = auth.authMessage {
                    Spacer().frame(height: 14)
                    AuthMessageView(text: message)
                }

                Spacer().frame(height: 12)

                RoundedActionButton(
                    title: auth.isAuthLoading ? "Signing Up..." : "Sign Up",
                    background: .black,
                    foreground: .white,
                    disabled: auth.isAuthLoading,
                    action: onSignUp
                )

                Spacer().frame(height: 8)

                Button(action: onOpenLogin) {
                    HStack(spacing: 0) {
                        Text("Already have an account? ")
                            .font(.system(size: 13))
                            .foregroundStyle(.black.opacity(0.86))

                        Text("LOGIN")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(.black)
                    }
                }
                .buttonStyle(.plain)
                .disabled(auth.isAuthLoading)
                .padding(.bottom, 14)
            }
        }
    }
}
