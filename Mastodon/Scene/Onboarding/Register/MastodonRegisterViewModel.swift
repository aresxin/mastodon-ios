//
//  MastodonRegisterViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-5.
//

import Combine
import Foundation
import MastodonSDK
import UIKit
import MastodonAsset
import MastodonLocalization

final class MastodonRegisterViewModel {
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let domain: String
    let authenticateInfo: AuthenticationViewModel.AuthenticateInfo
    let instance: Mastodon.Entity.Instance
    let applicationToken: Mastodon.Entity.Token
    let viewDidAppear = CurrentValueSubject<Void, Never>(Void())

    @Published var avatarImage: UIImage? = nil
    @Published var name = ""
    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    @Published var reason = ""
    
    let usernameErrorPrompt = CurrentValueSubject<NSAttributedString?, Never>(nil)
    let emailErrorPrompt = CurrentValueSubject<NSAttributedString?, Never>(nil)
    let passwordErrorPrompt = CurrentValueSubject<NSAttributedString?, Never>(nil)
    let reasonErrorPrompt = CurrentValueSubject<NSAttributedString?, Never>(nil)
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<RegisterSection, RegisterItem>?
    let approvalRequired: Bool
    let applicationAuthorization: Mastodon.API.OAuth.Authorization
    
    @Published var usernameValidateState: ValidateState = .empty
    @Published var displayNameValidateState: ValidateState = .empty
    @Published var emailValidateState: ValidateState = .empty
    @Published var passwordValidateState: ValidateState = .empty
    @Published var reasonValidateState: ValidateState = .empty
        
    @Published var isRegistering = false
    @Published var isAllValid = false
    @Published var error: Error? = nil
    
    let avatarMediaMenuActionPublisher = PassthroughSubject<AvatarMediaMenuAction, Never>()

    init(
        context: AppContext,
        domain: String,
        authenticateInfo: AuthenticationViewModel.AuthenticateInfo,
        instance: Mastodon.Entity.Instance,
        applicationToken: Mastodon.Entity.Token
    ) {
        self.domain = domain
        self.context = context
        self.authenticateInfo = authenticateInfo
        self.instance = instance
        self.applicationToken = applicationToken
        self.approvalRequired = instance.approvalRequired ?? false
        self.applicationAuthorization = Mastodon.API.OAuth.Authorization(accessToken: applicationToken.accessToken)
        
        $name
            .map { name in
                guard !name.isEmpty else { return .empty }
                return .valid
            }
            .assign(to: \.displayNameValidateState, on: self)
            .store(in: &disposeBag)
        
        $username
            .map { username in
                guard !username.isEmpty else { return .empty }
                var isValid = true
                
                // regex opt-out way to check validation
                // allowed:
                // a-z (isASCII && isLetter)
                // A-Z (isASCII && isLetter)
                // 0-9 (isASCII && isNumber)
                // _ ("_")
                for char in username {
                    guard char.isASCII, char.isLetter || char.isNumber || char == "_" else {
                        isValid = false
                        break
                    }
                }
                return isValid ? .valid : .invalid
            }
            .assign(to: \.usernameValidateState, on: self)
            .store(in: &disposeBag)
        
        // TODO: check username available
//        username
//            .filter { !$0.isEmpty }
//            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
//            .removeDuplicates()
//            .compactMap { [weak self] text -> AnyPublisher<Result<Mastodon.Response.Content<Mastodon.Entity.Account>, Error>, Never>? in
//                guard let self = self else { return nil }
//                let query = Mastodon.API.Account.AccountLookupQuery(acct: text)
//                return context.apiService.accountLookup(domain: domain, query: query, authorization: self.applicationAuthorization)
//                    .map {
//                        response -> Result<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> in
//                        Result.success(response)
//                    }
//                    .catch { error in
//                        Just(Result.failure(error))
//                    }
//                    .eraseToAnyPublisher()
//            }
//            .switchToLatest()
//            .sink { [weak self] result in
//                guard let self = self else { return }
//                switch result {
//                case .success:
//                    let text = L10n.Scene.Register.Error.Reason.taken(L10n.Scene.Register.Error.Item.username)
//                    self.usernameErrorPrompt.value = MastodonRegisterViewModel.errorPromptAttributedString(for: text)
//                    self.usernameValidateState.value = .invalid
//                case .failure:
//                    break
//                }
//            }
//            .store(in: &disposeBag)
//        
//        usernameValidateState
//            .sink { [weak self] validateState in
//                if validateState == .valid {
//                    self?.usernameErrorPrompt.value = nil
//                }
//            }
//            .store(in: &disposeBag)

        $email
            .map { email in
                guard !email.isEmpty else { return .empty }
                return MastodonRegisterViewModel.isValidEmail(email) ? .valid : .invalid
            }
            .assign(to: \.emailValidateState, on: self)
            .store(in: &disposeBag)
        
        $password
            .map { password in
                guard !password.isEmpty else { return .empty }
                return password.count >= 8 ? .valid : .invalid
            }
            .assign(to: \.passwordValidateState, on: self)
            .store(in: &disposeBag)
        
        if approvalRequired {
            $reason
                .map { invite in
                    guard !invite.isEmpty else { return .empty }
                    return .valid
                }
                .assign(to: \.reasonValidateState, on: self)
                .store(in: &disposeBag)
        }
        
//        error
//            .sink { [weak self] error in
//                guard let self = self else { return }
//                let error = error as? Mastodon.API.Error
//                let mastodonError = error?.mastodonError
//                if case let .generic(genericMastodonError) = mastodonError,
//                   let details = genericMastodonError.details
//                {
//                    self.usernameErrorPrompt.value = details.usernameErrorDescriptions.first.flatMap { MastodonRegisterViewModel.errorPromptAttributedString(for: $0) }
//                    self.emailErrorPrompt.value = details.emailErrorDescriptions.first.flatMap { MastodonRegisterViewModel.errorPromptAttributedString(for: $0) }
//                    self.passwordErrorPrompt.value = details.passwordErrorDescriptions.first.flatMap { MastodonRegisterViewModel.errorPromptAttributedString(for: $0) }
//                    self.reasonErrorPrompt.value = details.reasonErrorDescriptions.first.flatMap { MastodonRegisterViewModel.errorPromptAttributedString(for: $0) }
//                } else {
//                    self.usernameErrorPrompt.value = nil
//                    self.emailErrorPrompt.value = nil
//                    self.passwordErrorPrompt.value = nil
//                    self.reasonErrorPrompt.value = nil
//                }
//            }
//            .store(in: &disposeBag)
//        
        let publisherOne = Publishers.CombineLatest4(
            $usernameValidateState,
            $displayNameValidateState,
            $emailValidateState,
            $passwordValidateState
        )
        .map {
            $0.0 == .valid &&
            $0.1 == .valid &&
            $0.2 == .valid &&
            $0.3 == .valid
        }
        
        let publisherTwo = $reasonValidateState.map { reasonValidateState -> Bool in
            guard self.approvalRequired else { return true }
            return reasonValidateState == .valid
        }
        
        Publishers.CombineLatest(
            publisherOne,
            publisherTwo
        )
        .map { $0 && $1 }
        .assign(to: \.isAllValid, on: self)
        .store(in: &disposeBag)
    }
}

extension MastodonRegisterViewModel {
    enum ValidateState {
        case empty
        case invalid
        case valid
    }
}

extension MastodonRegisterViewModel {
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    static func checkmarkImage(font: UIFont = .preferredFont(forTextStyle: .caption1)) -> UIImage {
        let configuration = UIImage.SymbolConfiguration(font: font)
        return UIImage(systemName: "checkmark.circle.fill", withConfiguration: configuration)!
    }
    
    static func xmarkImage(font: UIFont = .preferredFont(forTextStyle: .caption1)) -> UIImage {
        let configuration = UIImage.SymbolConfiguration(font: font)
        return UIImage(systemName: "xmark.octagon.fill", withConfiguration: configuration)!
    }

    static func attributedStringImage(with image: UIImage, tintColor: UIColor) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = image.withTintColor(tintColor)
        return NSAttributedString(attachment: attachment)
    }
    
    static func attributeStringForPassword(validateState: ValidateState) -> NSAttributedString {
        let font = UIFontMetrics(forTextStyle: .caption1).scaledFont(for: .systemFont(ofSize: 13, weight: .regular), maximumPointSize: 18)
        let attributeString = NSMutableAttributedString()

        let image = MastodonRegisterViewModel.checkmarkImage(font: font)
        attributeString.append(attributedStringImage(with: image, tintColor: validateState == .valid ? Asset.Colors.Label.primary.color : .clear))
        attributeString.append(NSAttributedString(string: " "))
        let eightCharactersDescription = NSAttributedString(string: L10n.Scene.Register.Input.Password.hint, attributes: [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: Asset.Colors.Label.primary.color])
        attributeString.append(eightCharactersDescription)
        
        return attributeString
    }
    
    static func errorPromptAttributedString(for prompt: String) -> NSAttributedString {
        let font = UIFontMetrics(forTextStyle: .caption1).scaledFont(for: .systemFont(ofSize: 13, weight: .regular), maximumPointSize: 18)
        let attributeString = NSMutableAttributedString()

        let image = MastodonRegisterViewModel.xmarkImage(font: font)
        attributeString.append(attributedStringImage(with: image, tintColor: Asset.Colors.danger.color))
        attributeString.append(NSAttributedString(string: " "))
        
        let promptAttributedString = NSAttributedString(string: prompt, attributes: [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: Asset.Colors.danger.color])
        attributeString.append(promptAttributedString)
        
        return attributeString
    }
}
