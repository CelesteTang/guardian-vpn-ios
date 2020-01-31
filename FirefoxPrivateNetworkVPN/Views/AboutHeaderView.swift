//
//  AboutHeaderView
//  FirefoxPrivateNetworkVPN
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Copyright © 2019 Mozilla Corporation.
//

import UIKit

class AboutHeaderView: UITableViewHeaderFooterView {
    static let height: CGFloat = UIScreen.isiPad ? 224.0 : 175.0

    @IBOutlet weak var appNameLabel: UILabel!
    @IBOutlet weak var appDescriptionLabel: UILabel!
    @IBOutlet weak var releaseLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!

    override func awakeFromNib() {
        appNameLabel.text = LocalizedString.aboutAppName.value
        appNameLabel.font = UIFont.custom(.metropolisSemiBold, size: 15)
        appNameLabel.textColor = UIColor.custom(.grey50)

        appDescriptionLabel.text = LocalizedString.aboutDescription.value
        appDescriptionLabel.font = UIFont.custom(.inter, size: 13)
        appDescriptionLabel.textColor = UIColor.custom(.grey40)

        releaseLabel.text = LocalizedString.aboutReleaseVersion.value
        releaseLabel.font = UIFont.custom(.metropolisSemiBold, size: 15)
        releaseLabel.textColor = UIColor.custom(.grey50)

        versionLabel.text = UIApplication.appVersion
        versionLabel.font = UIFont.custom(.inter, size: 13)
        versionLabel.textColor = UIColor.custom(.grey40)
    }
}
