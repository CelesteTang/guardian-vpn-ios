// SPDX-License-Identifier: MIT
// Copyright © 2018-2019 WireGuard LLC. All Rights Reserved.

import UIKit
import RxSwift

// TODO: This class is getting too big. We need to break it up among it's responsibilities.

class AccountManager: AccountManaging {
    static let sharedManager = AccountManager()
    var credentialsStore = CredentialsStore.sharedStore
    private(set) var account: Account?

    public var heartbeatFailedEvent = PublishSubject<Void>()

    private init() {
        //
    }

    func set(with account: Account, completion: ((Result<Void, Error>) -> Void)) {
        self.account = account
        retrieveDeviceAndVPNServers(completion: completion)
    }

    private func retrieveDeviceAndVPNServers(completion: (Result<Void, Error>) -> Void) {
        let dispatchGroup = DispatchGroup()

        var error: Error?
        if account?.currentDevice == nil {
            dispatchGroup.enter()

            addDevice { result in
                if case .failure(let deviceError) = result {
                    error = deviceError
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.enter()
        retrieveVPNServers { result in
            if case .failure(let vpnError) = result {
                error = vpnError
            }
            dispatchGroup.leave()
        }

        if let error = error {
            completion(.failure(error))
            return
        }
        completion(.success(()))
    }

    func login(completion: @escaping (Result<LoginCheckpointModel, Error>) -> Void) {
        GuardianAPI.initiateUserLogin(completion: completion)
    }

    func verify(url: URL, completion: @escaping (Result<VerifyResponse, Error>) -> Void) {
        GuardianAPI.verify(urlString: url.absoluteString) { result in
            completion(result.map { verifyResponse in
                UserDefaults.standard.set(verifyResponse.token, forKey: "token")
                return verifyResponse
            })
        }
    }

    @objc func pollUser() {
        retrieveUser { _ in }
    }

    func retrieveUser(completion: @escaping (Result<User, Error>) -> Void) {
        guard let account = account else {
            completion(Result.failure(GuardianFailReason.emptyToken))
            return // TODO: Handle this case?
        }
        GuardianAPI.accountInfo(token: account.token) { [weak self] result in
            if case .failure = result {
                self?.heartbeatFailedEvent.onNext(())
            }

            completion(result.map { user in
                account.user = user
                return user
            })
        }
    }

    func retrieveVPNServers(completion: @escaping (Result<[VPNCountry], Error>) -> Void) {
        guard let account = account else {
            completion(Result.failure(GuardianFailReason.emptyToken))
            return // TODO: Handle this case?
        }
        GuardianAPI.availableServers(with: account.token) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                do {
                    self.account?.availableServers = try result.get()
                } catch {
                    print(error)
                }
            }
        }
    }

    func addDevice(completion: @escaping (Result<Device, Error>) -> Void) {
        guard let account = account else {
            completion(Result.failure(GuardianFailReason.emptyToken))
            return // TODO: Handle this case?
        }

        let deviceBody: [String: Any] = ["name": UIDevice.current.name,
                                         "pubkey": credentialsStore.deviceKeys.devicePublicKey.base64Key() ?? ""]

        do {
            let body = try JSONSerialization.data(withJSONObject: deviceBody)
            GuardianAPI.addDevice(with: account.token, body: body) { [weak self] result in
                completion(result.map { device in
                    self?.account?.currentDevice = device
                    device.saveToUserDefaults()
                    return device
                })
            }
        } catch {
            completion(Result.failure(GuardianFailReason.couldNotCreateBody))
        }
    }

    func startHeartbeat() {
        Timer(timeInterval: 3600,
              target: self,
              selector: #selector(pollUser),
              userInfo: nil,
              repeats: true)
    }
}